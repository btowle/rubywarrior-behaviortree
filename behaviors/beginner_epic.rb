module Behavior
  def get_behavior
    BehaviorTree.target = self

    BehaviorTree.build(:all) do
      #choose target
      any_or_fail do
        all_or_fail do
          is { closest_target(:behind)[:distance] < closest_target(:ahead)[:distance] }
          is { closest_target(:ahead)[:type] != :archer }
          execute { set_target :behind }
          execute { reverse }
        end
        execute { set_target :ahead }
      end

      execute { look_behind }

      any_or_fail do
        #rescue
        all_or_fail do
          is { facing? :captive }
          execute { rescue! }
        end

        #melee
        all_or_fail do
          is { facing? :enemy }
          any_or_fail do
            all_or_fail {
              is { facing_enemy? }
              execute { attack! }
            }
            execute { pivot_adjacent! }
          end
        end

        #rest
        all_or_fail do
          is { !can_fight? :sludge }
          is { !alone? }
          execute { rest! }
        end

        #shoot
        all_or_fail do
          is { ranged_target? }
          execute { shoot! }
        end

        #movement
        any_or_fail do
          #change direction at walls
          all_or_fail do
            is { at? :wall }
            is { !at? :stairs }
            execute { reverse }
            any_or_fail do
              all_or_fail {
                is { ranged_target? }
                execute { shoot! }
              }
              execute { walk! }
            end
          end

          #retreat if we need to
          all_or_fail do
            is { in_danger? }
            is { can_fight? }
            is { facing? :wall }
            execute { walk! opposite_direction }
          end

          #don't finish if we haven't cleared level
          all_or_fail do
            is { at? :stairs }
            is { !cleared? }
            execute { reverse }
            execute { walk! }
          end

          execute { walk! }
        end
      end
    end
  end
end
