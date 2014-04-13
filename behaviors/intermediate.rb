module Behavior
  def get_behavior
    BehaviorTree.target = self
    @npcs[:sludge][:melee] = 9

    BehaviorTree.build(:all) do
      #always face stairs
      #sense enemies
      execute { feel_adjacent_units }
      execute { listen_for_units }

      #choose direction
      any_or_fail do
        all_or_fail do
          is { remaining_units[:bomb_captive].count > 0 }
          execute { change_direction remaining_units[:bomb_captive][0][:direction] }
        end
        all_or_fail do
          is { remaining_units[:captive].count > 0 }
          execute { change_direction remaining_units[:captive][0][:direction] }
        end
        all_or_fail do
          is { remaining_units[:enemy].count > 0 }
          execute { change_direction remaining_units[:enemy][0][:direction] }
        end

        execute { change_direction(toward_stairs) }
      end

      #pick action
      any_or_fail do
        #rush to bombs
        all_or_fail do
          is { remaining_units[:bomb_captive].count > 0 }
          is { !facing? :ticking }
          any_or_fail do

            #rest if can't bomb
            all_or_fail do
              is { !can_survive_bomb? }
              is { adjacent_units[:enemy][:number] == 0 }
              execute { heal! }
            end

            #handle blocked path
            all_or_fail do
              is { way_blocked? }
              any_or_fail do
                all_or_fail do
                  is { !way_blocked? :left }
                  execute { rotate :left }
                  execute { advance! }
                end
                all_or_fail do
                  is { !way_blocked? :right }
                  execute { rotate :right }
                  execute { advance! }
                end
                any_or_fail do
                  #bind enemies
                  all_or_fail do
                    is { adjacent_units[:enemy][:number] > 1 }
                    execute { bind_adjacent! }
                  end

                  #fight
                  any_or_fail do
                    all_or_fail do
                      is { good_bomb_target? }
                      execute { throw_bomb! }
                    end
                    execute { combat! :melee }
                  end
                end
              end
            end
            execute { advance! }
          end
        end

        #bind enemies
        all_or_fail do
          is { adjacent_units[:enemy][:number] > 1 }
          execute { bind_adjacent! }
        end

        #throw bombs
        all_or_fail do
          is { good_bomb_target? }
          execute { throw_bomb! }
        end

        #fight
        all_or_fail do
          is { adjacent_units[:enemy][:number] == 1 }

          execute { face_adjacent :enemy }

          execute { combat! :melee }
        end

        #handle bound units
        all_or_fail do
          is { way_blocked? }
          any_or_fail do
            all_or_fail do
              is { unit_in_direction == :captive }
              execute { save! }
            end
            all_or_fail do
              execute { combat! :melee }
            end
          end
        end

        #rest
        all_or_fail do
          is { !can_fight? remaining_units[:strongest_foe] }
          is { adjacent_units[:enemy][:number] == 0 }
          execute { heal! }
        end

        #move
        any_or_fail do
          #avoid early exit
          all_or_fail do
            is { can_feel? :stairs }
            is { remaining_units[:captive].count > 0 || remaining_units[:enemy].count > 0 }
            any_or_fail do
              all_or_fail do
                is { way_blocked? :right }
                execute { rotate :left }
              end
              execute { rotate :right }
            end
            execute { advance! }
          end

          execute { advance! }
        end

      end
    end
  end
end
