module Behavior
  def get_behavior
    BehaviorTree.target = self

    BehaviorTree.build(:all) do
      execute { change_direction(toward_stairs) }

      any_or_fail do
        all_or_fail do
          is { facing?(:enemy) }
          execute { combat! :melee }
        end

        execute { advance! }
      end
    end
  end
end
