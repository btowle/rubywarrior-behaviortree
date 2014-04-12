module BehaviorTree
  module Selector
    def selector_init
      @last_run_child = 0
      @children = Array.new
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
          return :running
        end
        return child_state if @exit_states.include? child_state
      end

      @default_return_state
    end

    def add_action!(action,condition=nil)
      add_child! new_action(action, condition)
    end

    def add_condition!(test)
      add_child! new_condition(test)
    end

    def new_action(action,condition=nil)
      return BehaviorTree::Action.new(action,condition)
    end

    def new_condition(test)
      return BehaviorTree::Condition.new(test)
    end
  end

  class Priority
    include Selector

    def initialize
      selector_init
      @default_return_state = :failure
      @exit_states = [:success, :error]
    end
  end

  class Sequencer
    include Selector

    def initialize
      selector_init
      @default_return_state = :success
      @exit_states = [:failure, :running, :error]
    end
  end

  class All
    include Selector
    def initialize
      selector_init
      @default_return_state = :success
      @exit_states = []
    end
  end

  module Leaf
    def run
      return @test.() if @action.nil?
      return @action.() if @test.nil? || @test.()

      :failure
    end
  end

  class Condition
    include Leaf

    def initialize(test)
      @test = test
    end
  end

  class Action
    include Leaf
    def initialize(action, test = nil)
      @action = action
      @test = test
    end
  end
end
