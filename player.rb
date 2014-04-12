load(File.dirname(__FILE__)+"/behaviortree_builder.rb")
load(File.dirname(__FILE__)+"/beginner_behavior.rb")

class Player
  include BeginnerBehavior
  attr_reader :warrior, :direction, :npcs_behind

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

  def unit_in(space)
    space.to_s.downcase.gsub(/\s+/, "_").to_sym
  end

  def opposite_direction
    case @direction
    when :forward
      return :backward
    else
      return :forward
    end
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

  def at_stairs?
    @warrior.look(@direction).each { |space|
      return true if space.stairs?
      break unless space.empty?
    }

    false
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

  def about_face!
    @warrior.pivot! @direction
    @direction = :forward
  end
end
