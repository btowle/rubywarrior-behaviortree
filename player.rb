load(File.dirname(__FILE__)+"/behaviortree.rb")

class Player
  def initialize
    @sludge_damage = 6

    @behavior = BehaviorTree::Priority.new()
    
    @behavior.add_child! attack_tree
    @behavior.add_child! rest_tree
    @behavior.add_child! walk_tree
  end

  def play_turn(warrior)
    @behavior.run(warrior)
  end

  def rest_tree
    rest_tree = BehaviorTree::Sequencer.new()
    rest_tree.add_child! BehaviorTree::Condition.new(->(warrior){
      return :failure if warrior.health > @sludge_damage

      :success
    })
    rest_tree.add_child! BehaviorTree::Action.new(->(warrior){
      warrior.rest!

      :success
    })

    rest_tree
  end

  def attack_tree
    attack_tree = BehaviorTree::Sequencer.new()
    attack_tree.add_child! BehaviorTree::Condition.new(->(warrior){
      return :failure if warrior.feel.empty?

      :success
    })
    attack_tree.add_child! BehaviorTree::Action.new(->(warrior){
      warrior.attack!
      
      :success
    })

    attack_tree
  end

  def walk_tree
    @behavior.add_child! BehaviorTree::Action.new(->(warrior){
      warrior.walk!
      
      :success
    })

  end
end
