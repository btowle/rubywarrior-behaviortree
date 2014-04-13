My solutions for ruby warrior. Uses a behavior tree DSL to interact with the warrior.

##Getting Started
1. Clone to a folder in your rubywarrior diretory
2. Create a new .rb file in behavior/
3. Copy lib/player_loader.rb to /rubywarrior/YOUR_CHARACTER/player.rb
4. Edit the paths in the new player.rb
4. Build your behavior tree (see beginner_epic.rb for an example)
5. Run rubywarrior

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
get_view          | look                      | 8               | 8
closest_target    | look                      | 8               | 8
at?               | look                      | 8               | 8
look_behind       | look                      | 8               | 8
alone?            | look                      | 8               | 8
toward_stairs     | direction_of_stairs       | -               | 1
*adjacent*        | feel?                     | 2               | 1
way_blocked?      | feel?                     | 2               | 1
unit_in_direction | feel?                     | 2               | 1
can_feel?         | feel?                     | 2               | 1
bind_adjacent     | bind!                     | -               | 3
listen_for_units  | listen/direction_of       | -               | 4
space_info        | direction_of              | -               | 4
good_bomb_target? | look                      |                 | 8
throw_bomb!       | detonate!                 | _               | 8
                  | distance_of               | _               | 9
##More Info
###Behavior Trees
- http://www.moddb.com/groups/indievault/tutorials/game-ai-behavior-tree
- http://www.altdevblogaday.com/2011/02/24/introduction-to-behavior-trees/
- http://aigamedev.com/open/article/bt-overview/
- http://aigamedev.com/open/article/behavior-trees-part1/
- http://aigamedev.com/open/article/behavior-trees-part2/
- http://aigamedev.com/open/article/behavior-trees-part3/
