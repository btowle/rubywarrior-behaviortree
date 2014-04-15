module Behavior
  def get_behavior
    BehaviorTree.target = self

    BehaviorTree.build(:all) do
      #choose target
      any_or_fail do
        all_or_fail do
          target_behind_closest?
          no_archer_ahead?
          set_target :behind
          reverse
        end
        set_target :ahead
      end

      look_behind

      any_or_fail do
        #rescue
        all_or_fail do
          facing? :captive
          rescue!
        end

        #melee
        all_or_fail do
          facing? :enemy
          any_or_fail do
            all_or_fail {
              facing_enemy?
              attack!
            }
            pivot_adjacent!
          end
        end

        #rest
        all_or_fail do
          not_can_fight? :sludge
          not_alone?
          rest!
        end

        #shoot
        all_or_fail do
          ranged_target?
          shoot!
        end

        #movement
        any_or_fail do
          #change direction at walls
          all_or_fail do
            at? :wall
            not_at? :stairs
            reverse
            any_or_fail do
              all_or_fail {
                ranged_target?
                shoot!
              }
              walk!
            end
          end

          #retreat if we need to
          all_or_fail do
            in_danger?
            can_fight?
            facing? :wall
            walk! opposite_direction
          end

          #don't finish if we haven't cleared level
          all_or_fail do
            at? :stairs
            not_cleared?
            reverse
            walk!
          end

          walk!
        end
      end
    end
  end
end
