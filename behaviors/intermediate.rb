module Behavior
  def get_behavior
    BehaviorTree.target = self

    BehaviorTree.build(:all) do
      execute { change_direction(toward_stairs) }
      execute { advance! }

    end
  end
end
