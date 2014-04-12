module BeginnerBehavior
  def get_behavior
    player = self

    BehaviorTree.build {
      action { player.choose_target }
      action { player.look_behind }

      until_success {
        #rescue
        until_failure {
          condition { player.warrior.feel(player.direction).captive? }
          action { player.warrior.rescue! player.direction }
        }

        #melee
        until_failure {
          condition { player.warrior.feel(player.direction).enemy? }
          until_success{
            until_failure {
              condition { player.ready_for_melee? }
              action { player.warrior.attack!(player.direction) }
            }
            action { player.about_face! }
          }
        }

        #rest
        until_failure {
          condition { player.weak? }
          condition { player.alone? }
          action { player.warrior.rest! }
        }

        #shoot
        until_failure {
          condition { player.ranged_target? }
          action { player.warrior.shoot!(player.direction) }
        }

        #walk
        until_success {
          #change direction at walls
          until_failure {
            condition { player.warrior.feel(player.direction).wall? }
            action { player.change_direction }
            until_success {
              until_failure {
                condition { player.ranged_target? }
                action { player.warrior.shoot!(player.direction) }
              }
              action { player.warrior.walk! player.direction }
            }
          }
          #retreat if we need to
          until_failure {
            condition { player.in_danger? }
            condition { player.can_fight? }
            condition { player.warrior.feel(player.opposite_direction).wall? }
            action { player.warrior.walk! player.opposite_direction }
          }
          #don't finish if we haven't cleared level
          until_failure {
            condition { player.at_stairs? }
            condition { player.npcs_behind }
            action { player.change_direction }
            action { player.warrior.walk! player.direction }
          }

          #walk
          action { player.warrior.walk! player.direction }
        }
      }
    }
  end
end
