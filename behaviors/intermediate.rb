module Behavior
  def get_behavior
    BehaviorTree.target = self

    BehaviorTree.build(:all) do
      #always face stairs
      #sense enemies
      execute { feel_adjacent_units }
      execute { listen_for_units }

      #choose direction
      any_or_fail do
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
        #bind enemies
        all_or_fail do
          is { adjacent_units[:enemy][:number] > 1 }
          execute { bind_adjacent! }
        end

        #fight
        all_or_fail do
          is { adjacent_units[:enemy][:number] == 1 }
          execute { face_adjacent :enemy }
          execute { combat! :melee }
        end

        #rest
        all_or_fail do
          is { !can_fight?(:thick_sludge) }
          is { adjacent_units[:enemy][:number] == 0 }
          execute { heal! }
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

        #move
        any_or_fail do
          #avoid early exit
          all_or_fail do
            is { can_feel? :stairs }
            is { remaining_units[:captive].count > 0 || remaining_units[:enemy].count > 0 }
            any_or_fail do
              all_or_fail do
                is { can_feel? :wall, :right }
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
