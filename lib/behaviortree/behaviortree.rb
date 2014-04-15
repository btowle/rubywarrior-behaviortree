module BehaviorTree
  def self.opposite result
    return :pass if result == :fail
    return :fail if result == :pass
  end

  class Branch
    def initialize(result, exit_state_or_all)
      @last_run_child = 0
      @children = Array.new

      @exit_states = [:error, :running]
      if exit_state_or_all == :all then
        @default_return_state = result
      else
        @default_return_state = BehaviorTree.opposite result
        @exit_states.push(exit_state_or_all)
      end
    end

    def add_child!(child)
      @children.push child
    end

    def run
      return :error if @children.count <= 0
      @children[@last_run_child..-1].each_with_index do |child, index|
        child_state = child.run
        if child_state == :running then
          @last_run_child = index
        end
        return child_state if @exit_states.include? child_state
      end

      @default_return_state
    end
  end

  class Leaf
    def initialize(&block)
      @function = lambda &block
    end
    def run
      return :pass if @function.call

      :fail
    end
  end
end
