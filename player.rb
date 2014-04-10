load(File.dirname(__FILE__)+"/behaviortree.rb")

class Player
  def initialize
    @direction = :backward

    @max_health = @last_health = 20

    @distance_to_archer = 100

    @damage = {
      :sludge => 6,
      :archer => 6,
      :thick_sludge => 13
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
    @warrior.health >= @last_health
    @warrior.look(@direction).each_with_index { |space,index|
      if space.to_s.match(/Ar/) then
        @distance_to_archer = index
        return false
      end
    }
  end

  def rescue_tree
    rescue_captive = BehaviorTree::Sequencer.new

    #if the space has a captive
    rescue_captive.add_condition! ->{
      return :success if @warrior.feel(@direction).captive?

      :failure
    }
    #rescue!
    rescue_captive.add_action! ->{
      @warrior.rescue! @direction

      :success
    }

    rescue_captive
  end

  def melee_tree
    melee = BehaviorTree::Sequencer.new

    #if the space is not empty
    melee.add_condition! ->{
      return :success if @warrior.feel(@direction).enemy?

      :failure
    }
    #turn to face enemy!
    turn_or_melee = BehaviorTree::Priority.new
    turn_or_melee.add_action! ->{
      if @direction != :forward then
        @warrior.pivot! @direction
        @direction = :forward
        return :success
      end

      :failure
    }
    #melee!
    turn_or_melee.add_action! ->{
      @warrior.attack! @direction
      
      :success
    }
    melee.add_child! turn_or_melee

    melee
  end

  def rest_tree
    rest = BehaviorTree::Sequencer.new
    #if not at max health
    rest.add_condition! ->{
      return :success if @warrior.health < @damage.values.max

      :failure
    }
    #if safe
    rest.add_condition! ->{
      return :success if safe?

      :failure
    }
    #rest!
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
        return :failure if space.to_s.match(/Ca|Sl|Th/)
        return :success if space.enemy? && space.to_s.match(/Wi/)
        return :success if space.enemy? && 
                           space.to_s.match(/Ar/) && 
                           @warrior.health > @damage[:archer] && 
                           @distance_to_archer > 1
      }

      :failure
    }

    shoot.add_action! ->{
      @warrior.shoot! @direction

      :success
    }

    shoot
  end

  def walk_tree
    walk = BehaviorTree::Priority.new

    change_direction = BehaviorTree::Sequencer.new
    #if there is a wall
    change_direction.add_condition! ->{
      return :success if @warrior.feel(@direction).wall?

      :failure
    }
    #change_direction
    change_direction.add_action! ->{
      @direction = opposite_direction

      :success
    }
    walk.add_child! change_direction

    retreat = BehaviorTree::Sequencer.new
    #if not safe
    retreat.add_condition! ->{
      return :failure if safe?

      :success
    }
    #if weaker than an archer
    retreat.add_condition! ->{
      return :success if @warrior.health < @damage[:archer]

      :failure
    }
    #if there is room to walk back
    retreat.add_condition! ->{
      @warrior.look(opposite_direction)[0..2-@distance_to_archer].each { |space|
        return :failure if space.wall?
      }
    }
    #step back
    retreat.add_action! ->{
      @warrior.walk! opposite_direction
    }

    walk.add_child! retreat

    #walk direction
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
