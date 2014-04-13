load(File.dirname(__FILE__)+"/behaviortree_builder.rb")

class Player
  include BeginnerBehavior

  def initialize
    @direction = :backward

    @distance_to_target = 100
    @look_range = 3
    @charge_range = 1

    @npcs = {
      :sludge => 6,
      :archer => 6,
      :thick_sludge => 0,
      :wizard => 0,
      :captive => 0
    }

    @npcs_behind = false
    @target = :nothing

    @behavior = get_behavior()
  end

  def play_turn(warrior)
    @warrior = warrior
    @behavior.run()
  end

  def is_npc?(unit)
    @npcs.keys.include? unit
  end

  def in_danger?
    @target == :archer
  end

  def damaged?
    warrior_do(:health) <= @npcs.values.max if warrior_do(:health)
  end

  def can_fight?(enemy=@target)
    is_npc?(enemy) && warrior_do(:health) > @npcs[enemy]
  end

  def out_of_charge_range?
    @distance_to_target > @charge_range
  end

  def facing_enemy?
    @direction == :forward
  end

  def alone?
    (closest_target(:ahead)[:distance] > @look_range && closest_target(:behind)[:distance] > @look_range)
  end

  def ranged_target?
    return true if [:wizard, :thick_sludge].include? @target
    return true if in_danger? && @target == :archer && can_fight? && out_of_charge_range?
    false
  end

  def at?(feature)
    get_view(@direction).each { |space|
      return true if is_feature?(space, feature)
      break unless space.empty?
    }

    false
  end

  def facing?(feature)
    is_feature? warrior_do(:feel, @direction), feature
  end

  def is_feature?(space, feature)
    space.send(feature.to_s.concat("?").intern)
  end

  def cleared?
    !@npcs_behind
  end

  def get_view direction
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

  def change_direction
    @direction = opposite_direction
    @npcs_behind = false
  end

  def opposite_direction
    case @direction
    when :forward
      return :backward
    else
      return :forward
    end
  end

  def unit_in(space)
    space.to_s.downcase.gsub(/\s+/, "_").to_sym
  end

  def about_face!
    return unless warrior_do(:pivot!, @direction)
    @direction = :forward
  end

  def save!
    warrior_do :rescue!, @direction
  end

  def combat!(type)
    case type
    when :melee
      warrior_do :attack!, @direction
    when :ranged
      warrior_do :shoot!, @direction
    end
  end

  def heal!
    warrior_do :rest!
  end

  def advance!
    warrior_do :walk!, @direction
  end

  def retreat!
    warrior_do :walk!, opposite_direction
  end

  def warrior_do ability, *args
    return unless warrior_can? ability
    @warrior.send ability, *args
  end

  def warrior_can? ability
    return true if @warrior.respond_to? ability

    puts "**WARNING** #{caller_locations(2,1)[0].label} requires warrior.#{ability}"

    false
  end
end
