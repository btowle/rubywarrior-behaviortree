load(File.dirname(__FILE__)+"/behaviortree_builder.rb")

class Player
  include BeginnerBehavior

  def initialize
    @direction = :backward

    @max_health = @last_health = 20

    @distance_to_target = 100
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
    @last_health = warrior.health
  end

  def is_npc?(unit)
    @npcs.keys.include? unit
  end

  def in_danger?
    @target == :archer
  end

  def damaged?
    @warrior.health <= @npcs.values.max
  end

  def can_fight?(enemy=@target)
    is_npc?(enemy) && @warrior.health > @npcs[enemy]
  end

  def out_of_charge_range?
    @distance_to_target > @charge_range
  end

  def facing_enemy?
    @direction == :forward
  end

  def alone?
    @warrior.look(@direction).each { |space|
      return true if is_npc? unit_in(space)
    }

    false
  end

  def ranged_target?
    return true if [:wizard, :thick_sludge].include? @target
    return true if in_danger? && @target == :archer && can_fight? && out_of_charge_range?
    false
  end

  def at?(feature)
    @warrior.look(@direction).each { |space|
      return true if is_feature?(space, feature)
      break unless space.empty?
    }

    false
  end

  def facing?(feature)
    is_feature? @warrior.feel(@direction), feature
  end

  def is_feature?(space, feature)
    space.send(feature.to_s.concat("?").intern)
  end

  def cleared?
    !@npcs_behind
  end

  def closest_target(direction=:ahead)
    view = @warrior.look(@direction)
    view = @warrior.look(opposite_direction) if direction == :behind

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
    @warrior.look(opposite_direction).each{ |space|
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
    @warrior.pivot! @direction
    @direction = :forward
  end

  def save!
    @warrior.rescue! @direction
  end

  def combat!(type)
    case type
    when :melee
      @warrior.attack! @direction
    when :ranged
      @warrior.shoot! @direction
    end
  end

  def heal!
    @warrior.rest!
  end

  def advance!
    @warrior.walk! @direction
  end

  def retreat!
    @warrior.walk! opposite_direction
  end
end
