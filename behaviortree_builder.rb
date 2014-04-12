load(File.dirname(__FILE__)+"/behaviortree.rb")

module BehaviorTree

  def self.build(rootnode=nil,&block)
    tree = TreeBuilder.new(rootnode)
    tree.instance_eval(&block)
    return tree.root
  end

  class TreeBuilder
    attr_reader :root, :children

    def initialize(rootnode)
      @children = Array.new
      if rootnode
        @root = rootnode
      else
        @root = self
      end
    end

    def run
      @children.each do |child|
        child.run
      end
    end

    def add_child!(child)
      @children.push child
    end

    def until_success(&block)
      node = BehaviorTree::Priority.new
      @root.add_child! node
      BehaviorTree.build(node,&block)
    end

    def until_failure(&block)
      node = BehaviorTree::Sequencer.new
      @root.add_child! node
      BehaviorTree.build(node,&block)
    end

    def action(&block)
      @root.add_child!(BehaviorTree::Action.new(->{
        yield

        :success
      }))
    end

    def condition(&block)
      @root.add_child!(BehaviorTree::Condition.new(->{
        return :success if yield

        :failure
      }))
    end
  end
end
