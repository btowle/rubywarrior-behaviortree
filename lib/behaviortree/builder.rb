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

      @root = rootnode || BehaviorTree::Branch.new(:pass, :all)
    end

    def execute(&block)
      action { @target.instance_eval(&block) }
    end

    def is?(&block)
      condition { @target.instance_eval(&block) }
    end

    def method_missing(m, *args, &block)
      branch_regex =
      /(?<result>pass|fail)
          _after_(
            (first_(?<children_result>pass|fail)) |
            (?<all>all)
          )
      /x
      if matches = branch_regex.match(m) then
        exit_status_or_all = matches[:all] || matches[:children_result]
        node = BehaviorTree::Branch.new matches[:result].to_sym, exit_status_or_all.to_sym
        @root.add_child! node
        BehaviorTree.build(node, &block)
      elsif /\?$/.match(m) then
        condition { @target.send m, *args, &block }
      elsif @target then
        action { @target.send m ,*args ,&block }
      end
    end

private
    def action(&block)
      @root.add_child!(BehaviorTree::Leaf.new &block)
    end

    def condition(&block)
      @root.add_child!(BehaviorTree::Leaf.new &block)
    end
  end
end
