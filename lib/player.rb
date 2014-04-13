load(File.dirname(__FILE__)+"/behaviortree_builder.rb")

class Player
  include Behavior
  attr_reader :adjacent_units, :remaining_units

  def initialize
    @direction = :backward

    @distance_to_target = 100
    @look_range = 3
    @charge_range = 1

    @npcs = {
      :sludge => { :melee => 6, :ranged => 0 },
      :archer => { :melee => 6, :ranged => 6 },
      :thick_sludge => { :melee => 15, :ranged => 0 },
      :wizard => { :melee => 20, :ranged => 0 },
      :captive => { :melee => 0, :ranged => 0 }
    }

    @directions = [ :forward, :right, :backward, :left ]

    @npcs_behind = false
    @target = :nothing
    @adjacent_units = {}

    @behavior = get_behavior()
  end

  def play_turn(warrior)
    @warrior = warrior
    @behavior.run()
  end

  def is_npc?(unit)
    @npcs.keys.include? unit
  end

  def in_danger?
    @target == :archer
  end

  def damaged?
    warrior_do(:health) <= @npcs.values.max if warrior_do(:health)
  end

  def can_fight?(enemy=@target, combat_type=:melee)
    return is_npc?(enemy) && warrior_do(:health) > @npcs[enemy][combat_type]
  end

  def out_of_charge_range?
    @distance_to_target > @charge_range
  end

  def facing_enemy?
    @direction == :forward
  end

  def listen_for_units
    @remaining_units = {
                        :number => 0,
                        :enemy => [],
                        :captive => [],
                        :strongest_foe => :nothing
                       }
    warrior_do(:listen).each { |space|
      @remaining_units[:number] += 1
      info = space_info(space)
      if info[:type] == :captive then
        @remaining_units[:captive].push info
      else
        @remaining_units[:enemy].push info
        if @remaining_units[:strongest_foe] != :nothing &&
           @npcs[info[:type]].values.max > @remaining_units[:strongest_foe] then
          @remaining_units[:strongest_foe] = info[:type]
        end
      end
    }
  end

  def space_info(space)
    return {
            :direction => warrior_do(:direction_of,space),
            :type => unit_in(space)
           }
  end

  def feel_adjacent_enemies
    adjacent_enemies = []
    @directions.each { |d|
      adjacent_enemies.push({ :direction => d, :type => unit_in(warrior_do(:feel,d))}) if warrior_do(:feel, d).enemy?
    }

    adjacent_enemies
  end

  def feel_adjacent_units
    @adjacent_units = { :enemy => {
                          :number => 0,
                          :list => {
                            :forward => nil,
                            :backward => nil,
                            :left => nil,
                            :right => nil
                          }
                        }
                      }
    feel_adjacent_enemies.each { |enemy|
      @adjacent_units[:enemy][:number] += 1
      @adjacent_units[:enemy][:list][enemy[:direction]] = enemy[:type]
    }

    @adjacent_units
  end

  def act_on_adjacent(type=:enemy,&block)
    @adjacent_units[type][:list].each_pair { |direction, type|
      if type then
        yield direction, type
        break
      end
    }
  end

  def face_adjacent(type=:enemy)
    act_on_adjacent(:enemy) do |direction, type|
      change_direction direction
    end
  end

  def alone?
    (closest_target(:ahead)[:distance] > @look_range && closest_target(:behind)[:distance] > @look_range)
  end

  def ranged_target?
    return true if [:wizard, :thick_sludge].include? @target
    return true if in_danger? && @target == :archer && can_fight? && out_of_charge_range?
    false
  end

  def at?(feature)
    get_view(@direction).each { |space|
      return true if is_feature?(space, feature)
      break unless space.empty?
    }

    false
  end

  def facing?(feature)
    can_feel?(feature)
  end

  def is_feature?(space, feature)
    space.send(feature.to_s.concat("?").intern)
  end

  def can_feel?(feature, direction=@direction)
    is_feature? warrior_do(:feel, direction), feature
  end

  def cleared?
    !@npcs_behind
  end

  def way_blocked?(direction=@direction)
    !warrior_do(:feel, direction).empty?
  end

  def get_view direction
    view = warrior_do(:look, direction)
    return view if view

    []
  end

  def closest_target(direction=:ahead)
    view = get_view(@direction)
    view = get_view(opposite_direction) if direction == :behind

    target_distance = 100
    target_type = nil

    view.each_with_index { |space, index|
      if is_npc?(unit_in(space)) && index < target_distance then
        target_distance = index
        target_type = unit_in(space)
      end
    }

    return { :distance => target_distance, :type => target_type }
  end

  def set_target(direction)
    target_info = closest_target(direction)

    @target = target_info[:type]
    @distance_to_target = target_info[:distance]
  end

  def look_behind
    get_view(opposite_direction).each { |space|
      @npcs_behind = true if space.enemy?
    }
  end

  def rotate(turn_direction=:right)
    dir = 1
    dir = -1 if turn_direction == :left
    @direction = @directions[(@directions.find_index(@direction)+dir)%4]
  end

  def change_direction(new_direction=opposite_direction)
    @direction = new_direction
    @npcs_behind = false
  end

  def opposite_direction
    case @direction
    when :forward
      return :backward
    else
      return :forward
    end
  end

  def toward_stairs
    warrior_do(:direction_of_stairs)
  end

  def unit_in(space)
    space.to_s.downcase.gsub(/\s+/, "_").to_sym
  end

  def unit_in_direction(direction=@direction)
    unit_in(warrior_do(:feel, direction))
  end

  def about_face!
    return unless warrior_do(:pivot!, @direction)
    @direction = :forward
  end

  def save!
    warrior_do :rescue!, @direction
  end

  def combat!(type)
    case type
    when :melee
      warrior_do :attack!, @direction
    when :ranged
      warrior_do :shoot!, @direction
    end
  end

  def heal!
    warrior_do :rest!
  end

  def advance!
    warrior_do :walk!, @direction
  end

  def retreat!
    warrior_do :walk!, opposite_direction
  end

  def warrior_do ability, *args
    return unless warrior_can? ability
    @warrior.send ability, *args
  end

  def warrior_can? ability
    return true if @warrior.respond_to? ability

    puts "**WARNING** #{caller_locations(2,1)[0].label} requires warrior.#{ability}"

    false
  end

  def bind_adjacent!
    act_on_adjacent(:enemy) do |direction, type|
      warrior_do(:bind!, direction)
    end
  end
end
