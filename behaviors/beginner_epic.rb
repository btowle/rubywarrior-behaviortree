module BeginnerBehavior
  def get_behavior
    player = self

    BehaviorTree.target = self

    BehaviorTree.build(:all) {
      #choose target
      any_or_fail {
        all_or_fail {
          is { closest_target(:behind)[:distance] < closest_target(:ahead)[:distance] }
          is { closest_target(:ahead)[:type] != :archer }
          execute { set_target :behind }
          execute { change_direction }
        }
        execute { set_target :ahead }
      }

      execute { look_behind }

      any_or_fail {
        #rescue
        all_or_fail {
          is { facing? :captive }
          execute { save! }
        }

        #melee
        all_or_fail {
          is { facing? :enemy }
          any_or_fail{
            all_or_fail {
              is { facing_enemy? }
              execute { combat! :melee }
            }
            execute { about_face! }
          }
        }

        #rest
        all_or_fail {
          is { damaged? }
          is { alone? }
          execute { heal! }
        }

        #shoot
        all_or_fail {
          is { ranged_target? }
          execute { combat! :ranged }
        }

        #movement
        any_or_fail {
          #change direction at walls
          all_or_fail {
            is { at? :wall }
            is { !at? :stairs }
            execute { change_direction }
            any_or_fail {
              all_or_fail {
                is { ranged_target? }
                execute { combat! :ranged }
              }
              execute { advance! }
            }
          }

          #retreat if we need to
          all_or_fail {
            is { in_danger? }
            is { can_fight? }
            is { facing? :wall }
            execute { retreat! }
          }

          #don't finish if we haven't cleared level
          all_or_fail {
            is { at? :stairs }
            is { !cleared? }
            execute { change_direction }
            execute { advance! }
          }

          execute { advance! }
        }
      }
    }
  end
end
