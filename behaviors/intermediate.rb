module Behavior
  def get_behavior
    BehaviorTree.target = self

    BehaviorTree.build(:all) do

    end
  end
end
