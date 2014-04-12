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

Player Method | Required Warrior Methods
--------------|-------------------------
about_face!   | pivot!
save!         | rescue!
combat! :melee| attack!
combat! :ranged| shoot!
heal!         | rest!
advance!      | walk!
retreat!      | walk!

##More Info
###Behavior Trees
- http://www.moddb.com/groups/indievault/tutorials/game-ai-behavior-tree
- http://www.altdevblogaday.com/2011/02/24/introduction-to-behavior-trees/
- http://aigamedev.com/open/article/bt-overview/
- http://aigamedev.com/open/article/behavior-trees-part1/
- http://aigamedev.com/open/article/behavior-trees-part2/
- http://aigamedev.com/open/article/behavior-trees-part3/
