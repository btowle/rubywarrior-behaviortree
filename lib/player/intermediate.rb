load(File.dirname(__FILE__)+"/base.rb")

class Player < BasePlayer
  ##CONDITIONS
  def good_bomb_target?
    get_view[0].enemy? && get_view[1].enemy?
  end
  def can_survive_bomb?
    warrior_do(:health) > (@@bomb_damage + 8)
  end
  def outnumbered?
    @adjacent_units[:enemy][:number] > 1
  end

  def in_melee_range?
    @adjacent_units[:enemy][:number] > 0
  end

  def one_on_one?
    in_melee_range? && not_outnumbered?
  end

  def way_blocked?(direction=@direction)
    !warrior_do(:feel, direction).empty?
  end

  @@directions.each do |direction|
    define_method(direction.to_s+"_blocked?") do
      way_blocked?(direction)
    end
  end

  [:ticking, :captive, :enemy].each do |type|
    define_method(type.to_s+"_remaining?") do
      return @remaining_units[type].count > 0
    end
    define_method("adjacent_to_"+type.to_s+"?") do
      @adjacent_units[type][:number] > 0
    end
  end

  ##SENSES
  def listen_for_units
    @remaining_units = {
                        :number => 0,
                        :enemy => [],
                        :captive => [],
                        :ticking => [],
                        :strongest_foe => :captive,
                        :closest_foe => { :type => :nothing, :distance => 1000 }
                       }

    warrior_do(:listen).each { |space|
      @remaining_units[:number] += 1
      info = space_info space

      if unit_in(space) == :captive then
        @remaining_units[:ticking].push(info) if is_feature?(space, :ticking)
        @remaining_units[:captive].push info
      else
        @remaining_units[:enemy].push info
        if @remaining_units[:strongest_foe] == :captive ||
           @npcs[unit_in(space)].values.max > @npcs[@remaining_units[:strongest_foe]].values.max then
          @remaining_units[:strongest_foe] = unit_in(space)
        end
        if info[:distance] < @remaining_units[:closest_foe][:distance] then
          @remaining_units[:closest_foe] = info
        end
      end
    }
  end

  def get_adjacent(feature)
    adjacent = []
    @@directions.each { |d|
      if is_feature?(warrior_do(:feel, d), feature) then
        adjacent.push({ :direction => d, :type => unit_in(warrior_do(:feel,d))})
      end
    }

    adjacent
  end

  def feel_adjacent_units
    @adjacent_units = {}
    @adjacent_units[:total] = 0
    @adjacent_units[:strongest_foe] = :captive
    [:enemy, :captive, :wall].each { |type|
      @adjacent_units[type] = {
                                :number => 0,
                                :list => {
                                  :right => nil,
                                  :backward => nil,
                                  :left => nil,
                                  :forward => nil
                                }
                              }

      get_adjacent(type).each { |unit|
        @adjacent_units[:total] += 1
        @adjacent_units[type][:number] += 1
        @adjacent_units[type][:list][unit[:direction]] = unit[:type]

        if type != :wall then
          if @adjacent_units[:strongest_foe] == :captive ||
             @npcs[unit[:type]].values.max > @npcs[@adjacent_units[:strongest_foe]].values.max then
            @adjacent_units[:strongest_foe] = unit[:type]
          end
        end
      }
    }

    @adjacent_units
  end

  ##UTILITY
  def space_info(space)
    return {
            :direction => warrior_do(:direction_of,space),
            :distance => warrior_do(:distance_of,space),
            :type => unit_in(space)
           }
  end

  ##ACTIONS
  #intermediate
  [:right, :left].each do |direction|
    define_method("turn_"+direction.to_s) do
      dir = 1
      dir = -1 if direction == :left
      @direction = @@directions[(@@directions.find_index(@direction)+dir)%4]
    end
  end
  def face_toward_stairs
    change_direction warrior_do(:direction_of_stairs)
  end

  [:ticking, :captive, :enemy].each do |type|
    define_method("face_remaining_"+type.to_s) do
      change_direction @remaining_units[type][0][:direction]
    end
    define_method("face_adjacent_"+type.to_s) do
      @adjacent_units[type][:list].each_pair { |direction, adjacent_type|
        if is_feature?(warrior_do(:feel, direction), type)then
          return change_direction direction
        end
      }
    end
  end
end
