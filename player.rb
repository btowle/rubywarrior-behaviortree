load(File.dirname(__FILE__)+"/behaviortree.rb")

class Player
  def initialize
    @direction = :backward

    @max_health = @last_health = 20

    @damage = {
      :sludge => 6,
      :thick_sludge => 12,
      :archer => 11
    }

    @behavior = BehaviorTree::Priority.new
    
    @behavior.add_child! rescue_tree
    @behavior.add_child! attack_tree
    @behavior.add_child! rest_tree
    @behavior.add_child! walk_tree
  end

  def play_turn(warrior)
    @warrior = warrior
    @behavior.run()
    @last_health = warrior.health
  end

  def safe?
    @warrior.health >= @last_health
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

  def attack_tree
    attack = BehaviorTree::Sequencer.new

    #if the space is not empty
    attack.add_condition! ->{
      return :success if @warrior.feel(@direction).enemy?

      :failure
    }
    #turn to face enemy!
    turn_or_attack = BehaviorTree::Priority.new
    turn_or_attack.add_action! ->{
      if @direction != :forward then
        @warrior.pivot! @direction
        @direction = :forward
        return :success
      end

      :failure
    }
    #attack!
    turn_or_attack.add_action! ->{
      @warrior.attack! @direction
      
      :success
    }
    attack.add_child! turn_or_attack

    attack
  end

  def rest_tree
    rest = BehaviorTree::Sequencer.new
    #if not at max health
    rest.add_condition! ->{
      return :success if @warrior.health < @max_health

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
