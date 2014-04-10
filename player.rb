load(File.dirname(__FILE__)+"/behaviortree.rb")

class Player
  def initialize
    @direction = :backward

    @max_health = @last_health = 20

    @distance_to_archer = 100
    @archer_melee_range = 1

    @damage = {
      :sludge => 6,
      :archer => 6,
      :thick_sludge => 0,
      :wizard => 0
    }

    @behavior = BehaviorTree::Priority.new

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

  def safe?
    @warrior.look(@direction).each_with_index { |space,index|
      if space.to_s.match(/Ar/) then
        @distance_to_archer = index
        return false
      end
    }

    true
  end

  def in_danger?
    !safe?
  end

  def healthy?
    @warrior.health > @damage.values.max
  end

  def weak?
    !healthy?
  end

  def can_fight?(enemy)
    @warrior.health > @damage[enemy]
  end

  def about_face!
    @warrior.pivot! @direction
    @direction = :forward
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
      return :success if safe?

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
        return :success if space.to_s.match(/^Wi|^Th/)
        return :success if space.to_s.match(/^Ar/) && 
                           can_fight?(:archer) && 
                           @distance_to_archer > @archer_melee_range
        return :failure if space.to_s.match(/^Ca|^Sl/)
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

      :success
    }
    
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
      @warrior.walk! @direction

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
