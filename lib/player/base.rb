load(File.dirname(__FILE__)+"/../behaviortree/builder.rb")


class BasePlayer
  include Behavior

  @@units = [ :sludge, :archer, :thick_sludge, :wizard, :captive ]
  @@space_features = [ :wall, :warrior, :golem, :player, :enemy,
                         :captive, :empty, :stairs, :ticking ]

  @@directions = [ :forward, :right, :backward, :left ]
  @@npcs = {
            :sludge => { :melee => 6, :ranged => 0 },
            :archer => { :melee => 6, :ranged => 6 },
            :thick_sludge => { :melee => 12, :ranged => 0 },
            :wizard => { :melee => 20, :ranged => 0 },
            :captive => { :melee => 0, :ranged => 0 }
          }
  @@look_range = 3
  @@charge_range = 1
  @@bomb_damage = 4

  def initialize
    @direction = :backward
    @distance_to_target = 100
    @npcs = @@npcs

    @behavior = get_behavior()
  end

  def play_turn(warrior)
    @warrior = warrior
    @behavior.run()
  end

  def alone?
    (closest_target(:ahead)[:distance] > @@look_range && closest_target(:behind)[:distance] > @@look_range)
  end

  def can_fight?(enemy=@target, combat_type=:melee)
    enemy ||= @remaining_units[:closest_foe][:type]
    return true if enemy == :nothing
    return is_npc?(enemy) && warrior_do(:health) > @@npcs[enemy][combat_type]
  end

  def cleared?
    !(@npcs_behind || (@remaining_units && @remaining_units[:number] > 0))
  end

  @@space_features.each do |feature|
    define_method("facing_"+feature.to_s+"?") do
      return true if facing? feature
    end
    define_method("at_"+feature.to_s+"?") do
      return true if at? feature
    end
  end

  def facing_captive?
    return true if unit_in_direction == :captive
  end

  def get_view direction=@direction
    view = warrior_do(:look, direction)
    return view if view

    []
  end

  def closest_target(direction=:ahead)
    view = get_view(@direction)
    view = get_view(opposite_direction) if direction == :behind

    target_distance = 100
    target_type = nil

    view.each_with_index { |space, index|
      if is_npc?(unit_in(space)) && index < target_distance then
        target_distance = index
        target_type = unit_in(space)
      end
    }

    return { :distance => target_distance, :type => target_type }
  end


  def change_direction(new_direction)
    @npcs_behind = false
    @direction = new_direction
  end

  def opposite_direction(direction=@direction)
    case direction
    when :forward
      return :backward
    when :backward
      return :forward
    when :right
      return :left
    when :left
      return :right
    when :ahead
      return :behind
    when :behind
      return :ahead
    end
  end

  def method_missing m, *args, &block
    if matches = /^not_(?<method_name>[^?\s]+\?)$/.match(m.to_s) then #not_[method_name]? == ![method_name]?
      !send(matches[:method_name], *args)
    else
      super
    end
  end

  #warrior methods with no arguments
  [:direction_of, :direction_of_stairs ,:distance_of,
  :rest!, :health].each do |method|
    define_method(method) do
      warrior_do(method)
    end
  end

  #warrior actions with direction arguments
  [:feel, :listen, :look,
   :attack!, :bind!, :detonate!, :shoot!,
   :rescue!, :pivot!, :walk!].each do |method|
    define_method(method) do |direction=@direction|
      warrior_do(method, direction)
    end
  end

  #[warrior_action]_adjacent!
  [:attack!, :bind!, :dentonate!, :shoot!].each do |method|
    name = /[^\!]+/.match(method).to_s+"_adjacent!"
    define_method(name) do
      @adjacent_units[:enemy][:list].each_pair { |direction, adjacent_type|
        if adjacent_type == @adjacent_units[:strongest_foe] then
          return warrior_do(method,direction)
        end
      }
    end
  end

private
  def warrior_do ability, *direction
    return unless warrior_can? ability
    @warrior.send ability, *direction
  end

  def warrior_can? ability
    return true if @warrior.respond_to? ability

    puts "**WARNING** #{caller_locations(2,1)[0].label} requires warrior.#{ability}"

    false
  end

  def at?(feature)
    get_view(@direction).each { |space|
      return true if is_feature?(space, feature)
      break unless space.empty?
    }

    false
  end

  def facing?(feature, direction=@direction)
    is_feature? warrior_do(:feel, direction), feature
  end

  def is_feature?(space, feature)
    space.send(feature.to_s.concat("?").to_sym)
  end

  def is_npc?(unit)
    @@npcs.keys.include? unit
  end

  def unit_in(space)
    space.to_s.downcase.gsub(/\s+/, "_").to_sym
  end

  def unit_in_direction(direction=@direction)
    unit_in(warrior_do(:feel, direction))
  end
end
