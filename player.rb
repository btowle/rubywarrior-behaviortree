load(File.dirname(__FILE__)+"/behaviortree.rb")

class Player
  def initialize
    @behavior = BehaviorTree::Priority.new()
    
    attack = BehaviorTree::Sequencer.new()
    attack.add_child! BehaviorTree::Condition.new(->(warrior){
      return :failure if warrior.feel.empty?

      :success
    })
    attack.add_child! BehaviorTree::Action.new(->(warrior){
      warrior.attack!
      
      :success
    })
    @behavior.add_child! attack

    @behavior.add_child! BehaviorTree::Action.new(->(warrior){
      warrior.walk!
      
      :success
    })
  end

  def play_turn(warrior)
    @behavior.run(warrior)
  end
end
