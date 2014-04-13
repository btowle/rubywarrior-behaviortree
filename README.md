My solutions for ruby warrior. Uses a behavior tree DSL to interact with the warrior.

##Getting Started
1. Move the files into your ruby warrior character directory.
2. Create a new .rb file in behavior/
3. Replace beginner_epic.rb with your filename in the player_loader.rb
4. Replace /path/to/character/player.rb with lib/player_loader.rb (or symlink it)
5. Build your behavior tree (see beginner_epic.rb for an example)
6. Run rubywarrior

Note: If your character is already in epic mode, you can skip steps 3-5 and watch the beginner_epic behavior

##Player > Warrior mapping

Player Method     | Required Warrior Methods  | Beginner Level  | Intermediate Level
-------------     | ------------------------  | --------------  | ------------------
advance!          | walk!                     | 1               | 1
retreat!          | walk!                     | 1               | 1
facing?           | feel?                     | 2               | 1
combat! :melee    | attack!                   | 2               | 2
heal!             | rest!                     | 3               | 2
damaged?          | health                    | 3               | 2
can_fight?        | health                    | 3               | 2
save!             | rescue!                   | 5               | 3
about_face!       | pivot!                    | 7               | -
combat! :ranged   | shoot!                    | 8               | -
closest_target    | look                      | 8               | 8
at?               | look                      | 8               | 8
look_behind       | look                      | 8               | 8
alone?            | look                      | 8               | 8
                  | direction_of_stairs       | -               | 1
                  | bind!                     | -               | 3
                  | listen                    | -               | 4
                  | direction_of              | -               | 4
                  | detonate!                 | _               | 8
                  | distance_of               | _               | 9
##More Info
###Behavior Trees
- http://www.moddb.com/groups/indievault/tutorials/game-ai-behavior-tree
- http://www.altdevblogaday.com/2011/02/24/introduction-to-behavior-trees/
- http://aigamedev.com/open/article/bt-overview/
- http://aigamedev.com/open/article/behavior-trees-part1/
- http://aigamedev.com/open/article/behavior-trees-part2/
- http://aigamedev.com/open/article/behavior-trees-part3/
