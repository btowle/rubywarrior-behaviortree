load(File.dirname(__FILE__)+"/behaviortree.rb")

module BehaviorTree
  def self.target=(value)
    TreeBuilder.target = value
  end

  def self.build(rootnode=nil,&block)
    tree = TreeBuilder.new(rootnode)
    tree.instance_eval(&block)
    return tree.root
  end

  class TreeBuilder
    attr_reader :root, :children

    def self.target=(value)
      @@target = value
    end

    def initialize(rootnode)
      @target = @@target

      rootnode ||= :all

      case rootnode
      when :all
        @root = BehaviorTree::All.new
      when :all_or_fail
        @root = BehaviorTree::Sequencer.new
      when :any_or_fail
        @root = BehaviorTree::Priority.new
      else
        @root = rootnode
      end
    end

    def any_or_fail(&block)
      node = BehaviorTree::Priority.new
      @root.add_child! node
      BehaviorTree.build(node,&block)
    end

    def all_or_fail(&block)
      node = BehaviorTree::Sequencer.new
      @root.add_child! node
      BehaviorTree.build(node,&block)
    end

    def all(&block)
      node = BehaviorTree::All.new
      @root.add_child! node
      BehaviorTree.build(node,&block)
    end

    def execute(&block)
      @root.add_child!(BehaviorTree::Action.new(->{
        yield

        :success
      }))
    end

    def is(&block)
      @root.add_child!(BehaviorTree::Condition.new(->{
        return :success if yield

        :failure
      }))
    end

    def method_missing(m, *args, &block)
      if @target
        @target.send m ,*args ,&block
      end
    end
  end
end
