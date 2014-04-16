module Behavior
  def get_behavior
    BehaviorTree.parent = self
    @npcs[:sludge][:melee] = 9

    BehaviorTree.build do
      #always face stairs
      #sense enemies
      execute { feel_adjacent_units }
      execute { listen_for_units }

      #choose direction
      branch :pass_after_first_pass do
        branch :fail_after_first_fail do
          is? { remaining_units[:ticking].count > 0 }
          execute { change_direction remaining_units[:ticking][0][:direction] }
        end
        branch :fail_after_first_fail do
          is? { remaining_units[:captive].count > 0 }
          execute { change_direction remaining_units[:captive][0][:direction] }
        end
        branch :fail_after_first_fail do
          is? { remaining_units[:enemy].count > 0 }
          execute { change_direction remaining_units[:closest_foe][:direction] }
        end
        execute { change_direction(toward_stairs) }
      end

      #pick action
      branch :pass_after_first_pass do
        #rush to bombs
        branch :fail_after_first_fail do
          is? { remaining_units[:ticking].count > 0 }
          is? { not_facing? :ticking }
          branch :pass_after_first_pass do
            #rest if can't bomb
            branch :fail_after_first_fail do
              is? { not_can_survive_bomb? }
              is? { adjacent_units[:enemy][:number] == 0 }
              is? { not_alone? }
              is? { not_at? :captive }
              execute { rest! }
            end

            #handle blocked path
            branch :fail_after_first_fail do
              is? { way_blocked? }
              branch :pass_after_first_pass do
                branch :fail_after_first_fail, :fight_through do
                  branch :pass_after_first_pass, :bind_or_fight do
                    branch :fail_after_first_fail, :bind_enemies do
                      is? { adjacent_units[:enemy][:number] > 1 }
                      execute { bind_adjacent! }
                    end
                    branch(:pass_after_first_pass, :bomb_or_fight) do
                      branch :fail_after_first_fail do
                        is? { good_bomb_target? }
                        execute { detonate! }
                      end
                      execute { attack! }
                    end
                  end
                end
                branch :fail_after_first_fail, :face_open_direction do
                  execute { rotate :left }
                  branch :fail_after_first_fail do
                    is? { way_blocked? }
                    execute { rotate :right }
                    execute { rotate :right }
                    is? { way_blocked? }
                    execute { rotate :left }
                  end
                end
              end
            end
            execute { walk! }
          end
        end

        #bind enemies
        copy_branch :bind_enemies

        #fight
        branch :fail_after_first_fail do
          is? { adjacent_units[:enemy][:number] == 1 }
          execute { face_adjacent :enemy }
          copy_branch(:bomb_or_fight)
        end

        #handle bound units
        branch :fail_after_first_fail do
          is? { way_blocked? }
          branch :pass_after_first_pass do
            branch :fail_after_first_fail do
              is? { unit_in_direction == :captive }
              execute { rescue! }
            end
            branch :fail_after_first_fail do
              is? { can_fight? unit_in_direction }
              execute { attack! }
            end
          end
        end

        #rest
        branch :fail_after_first_fail do
          is? { not_can_fight? remaining_units[:closest_foe][:type] }
          is? { adjacent_units[:enemy][:number] == 0 }
          execute { rest! }
        end

        #move
        branch :pass_after_first_pass do
          #avoid early exit
          branch :fail_after_first_fail do
            is? { facing? :stairs }
            not_cleared?
            branch :pass_after_first_pass do
              branch :fail_after_first_fail do
                is? { way_blocked? :right }
                execute { rotate :left }
              end
              execute { rotate :right }
            end
            execute { walk! }
          end
          execute { walk! }
        end
      end
    end
  end
end
