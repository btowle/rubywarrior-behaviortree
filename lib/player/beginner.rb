load(File.dirname(__FILE__)+"/base.rb")

class Player < BasePlayer
  ##CONDITIONS
  def ranged_target?
    return true if [:wizard, :thick_sludge].include? @target
    return true if @target == :archer && can_fight? && @distance_to_target > @@charge_range
    false
  end

  [:ahead, :behind].each do |direction|
    @@units.each do |type|
      define_method(type.to_s+"_"+direction.to_s+"?") do
        return closest_target(direction)[:type] == type
      end
    end
    define_method("target_"+direction.to_s+"_closest?") do
      closest_target(direction)[:distance] < closest_target(opposite_direction direction)[:distance]
    end
    define_method("set_target_"+direction.to_s) do
      target_info = closest_target(direction)

      @target = target_info[:type]
      @distance_to_target = target_info[:distance]
    end
  end

  ##SENSES
  def look_behind
    get_view(opposite_direction).each { |space|
      @npcs_behind = true if space.enemy?
    }
  end

  ##ACTIONS
  def reverse
    change_direction opposite_direction
  end
end
