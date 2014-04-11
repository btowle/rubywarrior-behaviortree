load(File.dirname(__FILE__)+"/behaviortree.rb")

class Player
  def initialize
    @direction = :backward

    @max_health = @last_health = 20

    @distance_to_archer = 100
    @archer_melee_range = 1

    @npcs = {
      :sludge => 6,
      :archer => 6,
      :thick_sludge => 0,
      :wizard => 0,
      :captive => 0
    }

    @npcs_behind = false

    @behavior = BehaviorTree::Priority.new

    @behavior.add_child! choose_target_tree
    @behavior.add_child! look_behind_tree
    @behavior.add_child! rescue_tree
    @behavior.add_child! melee_tree
    @behavior.add_child! rest_tree
    @behavior.add_child! shoot_tree
    @behavior.add_child! walk_tree
  end

  def play_turn(warrior)
    @warrior = warrior
    @behavior.run()
    @last_health = warrior.health
  end

  def get_unit_in(space)
    space.to_s.downcase.gsub(/\s+/, "_").to_sym
  end

  def is_npc?(unit)
    @npcs.keys.include? unit
  end

  def safe?
    !near_archer?
  end

  def near_archer?
    @warrior.look(@direction).each_with_index { |space, index|
      if get_unit_in(space) == :archer then
        @distance_to_archer = index
        return true
      end
    }

    false
  end

  def in_danger?
    !safe?
  end

  def healthy?
    @warrior.health > @npcs.values.max
  end

  def weak?
    !healthy?
  end

  def can_fight?(enemy)
    @warrior.health > @npcs[enemy]
  end

  def out_of_charge_range?
    @distance_to_archer > @archer_melee_range
  end

  def about_face!
    @warrior.pivot! @direction
    @npcs_behind = false
  end

  def choose_target_tree
    choose_target = BehaviorTree::Sequencer.new
    choose_target.add_action! ->{
      ahead = @warrior.look(@direction)
      behind = @warrior.look(opposite_direction)

      closest_ahead = 100
      closest_behind = 200
      archer_ahead = false

      (0..2).each do |i|
        closest_behind = i if is_npc? get_unit_in(behind[i])
        closest_ahead = i if is_npc? get_unit_in(ahead[i])
        archer_ahead = true if get_unit_in(ahead[i]) == :archer
      end

      @direction = opposite_direction if closest_behind < closest_ahead && !archer_ahead

      :failure
    }

    choose_target
  end

  def look_behind_tree
    look_behind = BehaviorTree::Sequencer.new
    look_behind.add_action! ->{
      @warrior.look(opposite_direction).each{ |space|
        @npcs_behind = true if space.enemy?
      }

      :failure
    }

    look_behind
  end

  def rescue_tree
    rescue_captive = BehaviorTree::Sequencer.new

    rescue_captive.add_condition! ->{
      return :success if @warrior.feel(@direction).captive?

      :failure
    }
    rescue_captive.add_action! ->{
      @warrior.rescue! @direction

      :success
    }

    rescue_captive
  end

  def turn_or_melee_tree
    turn_or_melee = BehaviorTree::Priority.new

    turn_or_melee.add_action! ->{
      return :failure if @direction == :forward
      about_face!

      :success
    }

    turn_or_melee.add_action! ->{
      @warrior.attack! @direction
      
      :success
    }

    turn_or_melee
  end

  def melee_tree
    melee = BehaviorTree::Sequencer.new

    melee.add_condition! ->{
      return :success if @warrior.feel(@direction).enemy?

      :failure
    }

    melee.add_child! turn_or_melee_tree

    melee
  end

  def rest_tree
    rest = BehaviorTree::Sequencer.new

    rest.add_condition! ->{
      return :success if weak?

      :failure
    }
    rest.add_condition! ->{
      @warrior.look(@direction).each { |space|
        return :success if is_npc? get_unit_in(space)
      }
      :failure
    }
    rest.add_action! ->{
      @warrior.rest!

      :success
    }

    rest
  end

  def shoot_tree
    shoot = BehaviorTree::Sequencer.new

    shoot.add_condition! ->{
      @warrior.look(@direction).each { |space|
        return :failure if [:captive, :sludge].include? get_unit_in(space)
        return :success if [:wizard, :thick_sludge].include? get_unit_in(space)

        near_archer?
        if get_unit_in(space) == :archer && can_fight?(:archer) then
          return :success if out_of_charge_range?
          return :failure
        end
      }

      :failure
    }

    shoot.add_action! ->{
      @warrior.shoot! @direction

      :success
    }

    shoot
  end

  def change_direction_tree
    change_direction = BehaviorTree::Sequencer.new
    change_direction.add_condition! ->{
      return :success if @warrior.feel(@direction).wall?

      :failure
    }
    change_direction.add_action! ->{
      @direction = opposite_direction
      @npcs_behind = false

      :success
    }

    shoot_or_walk = BehaviorTree::Priority.new
    shoot_or_walk.add_child! shoot_tree
    shoot_or_walk.add_action! ->{
      @warrior.walk!

      :success
    }
    
    change_direction.add_child! shoot_or_walk

    change_direction
  end

  def retreat_tree
    retreat = BehaviorTree::Sequencer.new
    retreat.add_condition! ->{
      return :success if in_danger?

      :failure
    }
    retreat.add_condition! ->{
      return :success if !can_fight?(:archer)

      :failure
    }
    retreat.add_condition! ->{
      return :failure if @warrior.feel(opposite_direction).wall?

      :success
    }
    retreat.add_action! ->{
      @warrior.walk! opposite_direction
    }

    retreat
  end

  def walk_tree
    walk = BehaviorTree::Priority.new

    walk.add_child! change_direction_tree
    walk.add_child! retreat_tree

    walk.add_action! ->{
      if @warrior.feel(@direction).stairs? && @npcs_behind then
        about_face!
      else
        @warrior.walk! @direction
      end

      :success
    }

    walk
  end

  def opposite_direction
    case @direction
    when :forward
      return :backward
    else
      return :forward
    end
  end
end
