module BeginnerBehavior
  def get_behavior
    player = self

    BehaviorTree.build {
      #choose target
      any_or_fail {
        all_or_fail {
          is { player.closest_target(:behind)[:distance] < player.closest_target(:ahead)[:distance] }
          is { player.closest_target(:ahead)[:type] != :archer }
          execute { player.set_target :behind }
          execute { player.change_direction }
        }
        execute { player.set_target :ahead }
      }

      execute { player.look_behind }

      any_or_fail {
        #rescue
        all_or_fail {
          is { player.facing? :captive }
          execute { player.save! }
        }

        #melee
        all_or_fail {
          is { player.facing? :enemy }
          any_or_fail{
            all_or_fail {
              is { player.facing_enemy? }
              execute { player.combat! :melee }
            }
            execute { player.about_face! }
          }
        }

        #rest
        all_or_fail {
          is { player.damaged? }
          is { player.alone? }
          execute { player.heal! }
        }

        #shoot
        all_or_fail {
          is { player.ranged_target? }
          execute { player.combat! :ranged }
        }

        #movement
        any_or_fail {
          #change direction at walls
          all_or_fail {
            is { player.at? :wall }
            is { !player.at? :stairs }
            execute { player.change_direction }
            any_or_fail {
              all_or_fail {
                is { player.ranged_target? }
                execute { player.combat! :ranged }
              }
              execute { player.advance! }
            }
          }

          #retreat if we need to
          all_or_fail {
            is { player.in_danger? }
            is { player.can_fight? }
            is { player.facing? :wall }
            execute { player.retreat! }
          }

          #don't finish if we haven't cleared level
          all_or_fail {
            is { player.at? :stairs }
            is { !player.cleared? }
            execute { player.change_direction }
            execute { player.advance! }
          }

          execute { player.advance! }
        }
      }
    }
  end
end
