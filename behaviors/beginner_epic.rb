module Behavior
  def get_behavior
    BehaviorTree.target = self

    BehaviorTree.build do
      #choose target
      branch(:choose_target, :pass_after_all) {
        fail_after_first_fail {
          target_behind_closest?
          no_archer_ahead?
          set_target :behind
          reverse
        }
        set_target :ahead
      }

      look_behind

      pass_after_first_pass {
        #rescue
        fail_after_first_fail {
          facing? :captive
          rescue!
        }

        #melee
        fail_after_first_fail {
          facing? :enemy
          pass_after_first_pass {
            fail_after_first_fail {
              facing_enemy?
              attack!
            }
            pivot_adjacent!
          }
        }

        #rest
        fail_after_first_fail {
          not_can_fight? :sludge
          not_alone?
          rest!
        }

        #shoot
        fail_after_first_fail(:shoot) {
          ranged_target?
          shoot!
        }

        #movement
        pass_after_first_pass {
          #change direction at walls
          fail_after_first_fail {
            at? :wall
            not_at? :stairs
            reverse
            pass_after_first_pass {
              fail_after_first_fail (:shoot)
              walk!
            }
          }

          #retreat if we need to
          fail_after_first_fail {
            in_danger?
            can_fight?
            facing? :wall
            walk! opposite_direction
          }

          #don't finish if we haven't cleared level
          fail_after_first_fail {
            at? :stairs
            not_cleared?
            reverse
            walk!
          }
          walk!
        }
      }
    end
  end
end
