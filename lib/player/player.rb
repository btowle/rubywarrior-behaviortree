load(File.dirname(__FILE__)+"/../behaviortree/builder.rb")

class Player
  include Behavior

  @@units = [ :sludge, :archer, :thick_sludge, :wizard, :captive ]
  @@space_features = [ :wall, :warrior, :golem, :player, :enemy,
                       :captive, :empty, :stairs, :ticking ]
  @@directions = [ :forward, :right, :backward, :left ]

  def initialize
    @direction = :backward

    @distance_to_target = 100
    @look_range = 3
    @charge_range = 1
    @bomb_damage = 4


    @npcs = {
      :sludge => { :melee => 6, :ranged => 0 },
      :archer => { :melee => 6, :ranged => 6 },
      :thick_sludge => { :melee => 12, :ranged => 0 },
      :wizard => { :melee => 20, :ranged => 0 },
      :captive => { :melee => 0, :ranged => 0 }
    }

    @npcs_behind = false
    @adjacent_units = {}

    @behavior = get_behavior()
  end

  def play_turn(warrior)
    @warrior = warrior
    @behavior.run()
  end

  def can_fight?(enemy=@target, combat_type=:melee)
    enemy ||= @remaining_units[:closest_foe][:type]
    return true if enemy == :nothing
    return is_npc?(enemy) && warrior_do(:health) > @npcs[enemy][combat_type]
  end

  def facing_enemy?
    @direction == :forward
  end

  def good_bomb_target?
    get_view[0].enemy? && get_view[1].enemy?
  end

  def can_survive_bomb?
    warrior_do(:health) > (@bomb_damage + 8)
  end

  def listen_for_units
    @remaining_units = {
                        :number => 0,
                        :enemy => [],
                        :captive => [],
                        :ticking => [],
                        :strongest_foe => :captive,
                        :closest_foe => { :type => :nothing, :distance => 1000 }
                       }

    warrior_do(:listen).each { |space|
      @remaining_units[:number] += 1
      info = space_info space

      if unit_in(space) == :captive then
        @remaining_units[:ticking].push(info) if is_feature?(space, :ticking)
        @remaining_units[:captive].push info
      else
        @remaining_units[:enemy].push info
        if @remaining_units[:strongest_foe] == :captive ||
           @npcs[unit_in(space)].values.max > @npcs[@remaining_units[:strongest_foe]].values.max then
          @remaining_units[:strongest_foe] = unit_in(space)
        end
        if info[:distance] < @remaining_units[:closest_foe][:distance] then
          @remaining_units[:closest_foe] = info
        end
      end
    }
  end

  def space_info(space)
    return {
            :direction => warrior_do(:direction_of,space),
            :distance => warrior_do(:distance_of,space),
            :type => unit_in(space)
           }
  end

  def get_adjacent(feature)
    adjacent = []
    @@directions.each { |d|
      if is_feature?(warrior_do(:feel, d), feature) then
        adjacent.push({ :direction => d, :type => unit_in(warrior_do(:feel,d))})
      end
    }

    adjacent
  end

  def feel_adjacent_units
    @adjacent_units[:total] = 0
    @adjacent_units[:strongest_foe] = :captive
    [:enemy, :captive, :wall].each { |type|
      @adjacent_units[type] = {
                                :number => 0,
                                :list => {
                                  :right => nil,
                                  :backward => nil,
                                  :left => nil,
                                  :forward => nil
                                }
                              }

      get_adjacent(type).each { |unit|
        @adjacent_units[:total] += 1
        @adjacent_units[type][:number] += 1
        @adjacent_units[type][:list][unit[:direction]] = unit[:type]

        if type != :wall then
          if @adjacent_units[:strongest_foe] == :captive ||
             @npcs[unit[:type]].values.max > @npcs[@adjacent_units[:strongest_foe]].values.max then
            @adjacent_units[:strongest_foe] = unit[:type]
          end
        end
      }
    }

    @adjacent_units
  end

  def outnumbered?
    @adjacent_units[:enemy][:number] > 1
  end

  def in_melee_range?
    @adjacent_units[:enemy][:number] > 0
  end

  def one_on_one?
    in_melee_range? && not_outnumbered?
  end

  def alone?
    (closest_target(:ahead)[:distance] > @look_range && closest_target(:behind)[:distance] > @look_range)
  end

  def ranged_target?
    return true if [:wizard, :thick_sludge].include? @target
    return true if @target == :archer && can_fight? && @distance_to_target > @charge_range
    false
  end

  def cleared?
    !(@npcs_behind || (@remaining_units && @remaining_units[:number] > 0))
  end

  def way_blocked?(direction=@direction)
    !warrior_do(:feel, direction).empty?
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

  [:ahead, :behind].each do |direction|
    @@units.each do |type|
      name = type.to_s+"_"+direction.to_s+"?" #unit_ahead/behind?
      define_method(name) do
        return closest_target(direction)[:type] == type
      end
      define_method("no_"+name) do #no_unit_ahead/behind?
        !send(name)
      end
    end
    define_method("target_"+direction.to_s+"_closest?") do
      closest_target(direction)[:distance] < closest_target(opposite_direction direction)[:distance]
    end
  end

  def set_target(direction)
    target_info = closest_target(direction)

    @target = target_info[:type]
    @distance_to_target = target_info[:distance]
  end

  def look_behind
    get_view(opposite_direction).each { |space|
      @npcs_behind = true if space.enemy?
    }
  end

  def rotate(turn_direction=:right)
    dir = 1
    dir = -1 if turn_direction == :left
    @direction = @@directions[(@@directions.find_index(@direction)+dir)%4]
  end

  [:right, :left].each do |direction|
    define_method("turn_"+direction.to_s) do
      rotate direction
    end
  end

  def change_direction(new_direction)
    @npcs_behind = false
    @direction = new_direction
  end

  def reverse
    change_direction opposite_direction
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

  def face_toward_stairs
    change_direction warrior_do(:direction_of_stairs)
  end

  #not_booleans
  def method_missing m, *args, &block
    if matches = /^not_(?<method_name>[^?\s]+\?)$/.match(m.to_s) then
      !send(matches[:method_name], *args)
    else
      super
    end
  end

  @@directions.each do |direction|
    define_method(direction.to_s+"_blocked?") do
      way_blocked?(direction)
    end
  end

  #warrior methods with no arguments
  [:rest!, :health].each do |method|
    define_method(method) do
      warrior_do(method)
    end
  end

  #warrior methods with arguments
  [:direction_of, :direction_of_stairs ,:distance_of,
   :feel, :listen, :look,
   :attack!, :bind!, :detonate!, :shoot!,
   :rescue!, :pivot!, :walk!].each do |method|
    define_method(method) do |direction=@direction|
      warrior_do(method, direction)
    end
  end
  #[:walk!, :pivot!],[:rescue!]
  #warrior actions aimed at adjacent
  [:attack!, :bind!, :dentonate!, :shoot!].each do |method|
    name = /[^\!]+/.match(method).to_s+"_adjacent!"
    define_method(name) do
      @adjacent_units[:enemy][:list].each_pair { |direction, adjacent_type|
        if is_feature?(warrior_do(:feel, direction), :enemy) &&
           adjacent_type == @adjacent_units[:strongest_foe] then
          return warrior_do(method,direction)
        end
      }
    end
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

  [:ticking, :captive, :enemy].each do |type|
    define_method(type.to_s+"_remaining?") do
      return @remaining_units[type].count > 0
    end
    define_method("face_remaining_"+type.to_s) do
      change_direction @remaining_units[type][0][:direction]
    end
    define_method("adjacent_to_"+type.to_s+"?") do
      @adjacent_units[type][:number] > 0
    end
    define_method("face_adjacent_"+type.to_s) do
      @adjacent_units[type][:list].each_pair { |direction, adjacent_type|
        if is_feature?(warrior_do(:feel, direction), type)then
          return change_direction direction
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

  def unit_in(space)
    space.to_s.downcase.gsub(/\s+/, "_").to_sym
  end

  def unit_in_direction(direction=@direction)
    unit_in(warrior_do(:feel, direction))
  end

  def is_npc?(unit)
    @npcs.keys.include? unit
  end

end
