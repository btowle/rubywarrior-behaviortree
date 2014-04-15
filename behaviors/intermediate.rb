module Behavior
  def get_behavior
    BehaviorTree.target = self
    @npcs[:sludge][:melee] = 9

    BehaviorTree.build do
      #always face stairs
      #sense enemies
      execute { feel_adjacent_units }
      execute { listen_for_units }

      #choose direction
      pass_after_first_pass do
        fail_after_first_fail do
          is? { remaining_units[:bomb_captive].count > 0 }
          execute { change_direction remaining_units[:bomb_captive][0][:direction] }
        end
        fail_after_first_fail do
          is? { remaining_units[:captive].count > 0 }
          execute { change_direction remaining_units[:captive][0][:direction] }
        end
        fail_after_first_fail do
          is? { remaining_units[:enemy].count > 0 }
          execute { change_direction remaining_units[:enemy][0][:direction] }
        end
        execute { change_direction(toward_stairs) }
      end

      #pick action
      pass_after_first_pass do
        #rush to bombs
        fail_after_first_fail do
          is? { remaining_units[:bomb_captive].count > 0 }
          is? { not_facing? :ticking }
          pass_after_first_pass do
            #rest if can't bomb
            fail_after_first_fail do
              is? { not_can_survive_bomb? }
              is? { adjacent_units[:enemy][:number] == 0 }
              is? { not_alone? }
              is? { not_at? :captive }
              execute { rest! }
            end

            #handle blocked path
            fail_after_first_fail do
              is? { way_blocked? }
              pass_after_first_pass do
                #fight through
                fail_after_first_fail do
                  is? { adjacent_units[:total] }
                  pass_after_first_pass do
                    #bind enemies
                    fail_after_first_fail do
                      is? { adjacent_units[:enemy][:number] > 1 }
                      execute { bind_adjacent! }
                    end

                    #fight
                    pass_after_first_pass do
                      fail_after_first_fail do
                        is? { good_bomb_target? }
                        execute { detonate! }
                      end
                      execute { attack! }
                    end
                  end
                end
                #walk around
                fail_after_first_fail do
                  execute { rotate :left }
                  fail_after_first_fail do
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
        fail_after_first_fail do
          is? { adjacent_units[:enemy][:number] > 1 }
          execute { bind_adjacent! }
        end

        #throw bombs
        fail_after_first_fail do
          is? { good_bomb_target? }
          execute { detonate! }
        end

        #fight
        fail_after_first_fail do
          is? { adjacent_units[:enemy][:number] == 1 }
          execute { face_adjacent :enemy }
          execute { attack! }
        end

        #handle bound units
        fail_after_first_fail do
          is? { way_blocked? }
          pass_after_first_pass do
            fail_after_first_fail do
              is? { unit_in_direction == :captive }
              execute { rescue! }
            end
            fail_after_first_fail do
              is? { can_fight? unit_in_direction }
              execute { attack! }
            end
          end
        end

        #rest
        fail_after_first_fail do
          is? { not_can_fight? remaining_units[:closest_foe][:type] }
          is? { adjacent_units[:enemy][:number] == 0 }
          execute { rest! }
        end

        #move
        pass_after_first_pass do
          #avoid early exit
          fail_after_first_fail do
            is? { facing? :stairs }
            is? { remaining_units[:captive].count > 0 || remaining_units[:enemy].count > 0 }
            pass_after_first_pass do
              fail_after_first_fail do
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
