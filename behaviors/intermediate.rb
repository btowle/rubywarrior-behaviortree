module Behavior
  def get_behavior
    BehaviorTree.parent = self
    @npcs[:sludge][:melee] = 9

    BehaviorTree.build do
      feel_adjacent_units
      listen_for_units

      branch :pass_after_first_pass, :choose_direction do
        branch :fail_after_first_fail do
          ticking_remaining?
          face_remaining_ticking
        end
        branch :fail_after_first_fail do
          captive_remaining?
          face_remaining_captive
        end
        branch :fail_after_first_fail do
          enemy_remaining?
          face_remaining_enemy
        end
        face_toward_stairs
      end

      branch :pass_after_first_pass, :pick_action do
        branch :fail_after_first_fail, :rush_to_bombs do
          ticking_remaining?
          not_facing_ticking?
          branch :pass_after_first_pass do
            branch :fail_after_first_fail, :panic_heal do
              not_can_survive_bomb?
              not_in_melee_range?
              not_alone?
              not_at_captive?
              rest!
            end

            branch :fail_after_first_fail, :handle_blocked_path do
              way_blocked?
              branch :pass_after_first_pass do
                branch :fail_after_first_fail, :fight_through do
                  branch :pass_after_first_pass, :bind_or_fight do
                    branch :fail_after_first_fail, :bind_enemies do
                      outnumbered?
                      bind_adjacent!
                    end
                    branch(:pass_after_first_pass, :bomb_or_fight) do
                      branch :fail_after_first_fail do
                        good_bomb_target?
                        detonate!
                      end
                      attack!
                    end
                  end
                end
                branch :fail_after_first_fail, :face_open_direction do
                  turn_left
                  branch :fail_after_first_fail do
                    way_blocked?
                    turn_right
                    turn_right
                    way_blocked?
                    turn_left
                  end
                end
              end
            end
            walk!
          end
        end

        copy_branch :bind_enemies

        branch :fail_after_first_fail, :fight do
          one_on_one?
          face_adjacent_enemy
          copy_branch(:bomb_or_fight)
        end

        branch :fail_after_first_fail, :handle_bound_units do
          way_blocked?
          branch :pass_after_first_pass do
            branch :fail_after_first_fail do
              facing_captive?
              rescue!
            end
            branch :fail_after_first_fail do
              can_fight?
              attack!
            end
          end
        end

        branch :fail_after_first_fail, :rest do
          not_can_fight?
          not_in_melee_range?
          rest!
        end

        branch :pass_after_first_pass, :move do
          branch :fail_after_first_fail, :avoid_early_exit do
            facing_stairs?
            not_cleared?
            branch :pass_after_first_pass do
              branch :fail_after_first_fail do
                right_blocked?
                turn_left
              end
              turn_right
            end
            walk!
          end
          walk!
        end
      end
    end
  end
end
