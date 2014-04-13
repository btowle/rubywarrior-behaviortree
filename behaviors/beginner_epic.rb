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
          execute { change_direction }
        end
        execute { set_target :ahead }
      end

      execute { look_behind }

      any_or_fail do
        #rescue
        all_or_fail do
          is { facing? :captive }
          execute { save! }
        end

        #melee
        all_or_fail do
          is { facing? :enemy }
          any_or_fail do
            all_or_fail {
              is { facing_enemy? }
              execute { combat! :melee }
            }
            execute { about_face! }
          end
        end

        #rest
        all_or_fail do
          is { damaged? }
          is { !alone? }
          execute { heal! }
        end

        #shoot
        all_or_fail do
          is { ranged_target? }
          execute { combat! :ranged }
        end

        #movement
        any_or_fail do
          #change direction at walls
          all_or_fail do
            is { at? :wall }
            is { !at? :stairs }
            execute { change_direction }
            any_or_fail do
              all_or_fail {
                is { ranged_target? }
                execute { combat! :ranged }
              }
              execute { advance! }
            end
          end

          #retreat if we need to
          all_or_fail do
            is { in_danger? }
            is { can_fight? }
            is { facing? :wall }
            execute { retreat! }
          end

          #don't finish if we haven't cleared level
          all_or_fail do
            is { at? :stairs }
            is { !cleared? }
            execute { change_direction }
            execute { advance! }
          end

          execute { advance! }
        end
      end
    end
  end
end
