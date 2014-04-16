module Behavior
  def get_behavior
    BehaviorTree.parent = self

    BehaviorTree.build do
      branch(:pass_after_all, :choose_target) {
        branch(:fail_after_first_fail) {
          target_behind_closest?
          no_archer_ahead?
          set_target :behind
          reverse
        }
        set_target :ahead
      }

      look_behind

      branch(:pass_after_first_pass, :choose_warrior_action){
        branch(:fail_after_first_fail, :try_rescue ){
          facing_captive?
          rescue!
        }

        branch(:fail_after_first_fail, :try_melee){
          facing_enemy?
          branch(:pass_after_first_pass){
            branch(:fail_after_first_fail){
              facing_enemy?
              attack!
            }
            pivot_adjacent!
          }
        }

        branch(:fail_after_first_fail, :try_heal){
          not_can_fight? :sludge
          not_alone?
          rest!
        }

        branch(:fail_after_first_fail, :try_shoot) {
          ranged_target?
          shoot!
        }

        branch(:pass_after_first_pass, :try_move){
          branch(:fail_after_first_fail, :avoid_walls){
            at? :wall
            not_at? :stairs
            reverse
            branch(:pass_after_first_pass){
              copy_branch(:try_shoot)
              walk!
            }
          }

          branch(:fail_after_first_fail, :turn_around_if_not_clear){
            at_stairs?
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
