load(File.dirname(__FILE__)+"/behaviortree.rb")

class Player
  def initialize
    @last_health = 20

    @damage = {
      :sludge => 6,
      :thick_sludge => 12,
      :archer => 6
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
      return :success if @warrior.feel.captive?

      :failure
    }
    #rescue!
    rescue_captive.add_action! ->{
      @warrior.rescue!

      :success
    }

    rescue_captive
  end

  def attack_tree
    attack = BehaviorTree::Sequencer.new

    #if the space is not empty
    attack.add_condition! ->{
      return :failure if @warrior.feel.empty?

      :success
    }

    #attack!
    attack.add_action! ->{
      @warrior.attack!
      
      :success
    }

    attack
  end

  def rest_tree
    rest = BehaviorTree::Sequencer.new
    #if can't survive a fight with thick_sludge
    rest.add_condition! ->{
      return :failure if @warrior.health > @damage[:thick_sludge]

      :success
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
    walk = BehaviorTree::Sequencer.new
    #walk foward
    walk.add_action! ->{
      @warrior.walk!

      :success
    }

    walk
  end
end
