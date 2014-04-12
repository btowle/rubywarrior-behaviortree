load(File.dirname(__FILE__)+"/behaviortree_builder.rb")
load(File.dirname(__FILE__)+"/beginner_behavior.rb")

class Player
  include BeginnerBehavior

  def initialize
    @direction = :backward

    @max_health = @last_health = 20

    @distance_to_enemy = 100
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

  def weak?
    @warrior.health <= @npcs.values.max
  end

  def can_fight?(enemy=@target)
    is_npc?(enemy) && @warrior.health > @npcs[enemy]
  end

  def out_of_charge_range?
    @distance_to_enemy > @charge_range
  end

  def ready_for_melee?
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

  def choose_target
    ahead = @warrior.look(@direction)
    behind = @warrior.look(opposite_direction)

    closest_ahead = 100
    closest_behind = 200
    archer_ahead = false

    (0..2).each do |i|
      closest_behind = i if is_npc?(unit_in(behind[i])) && i < closest_behind
      closest_ahead = i if is_npc?(unit_in(ahead[i])) && i < closest_ahead
      archer_ahead = true if unit_in(ahead[i]) == :archer
    end

    if closest_behind < closest_ahead && !archer_ahead
      @direction = opposite_direction
      @npcs_behind = false
      @target = unit_in behind[closest_behind]
      @distance_to_enemy = closest_behind
    else
      @target = unit_in ahead[closest_ahead]
      @distance_to_enemy = closest_ahead
    end
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
