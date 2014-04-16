load(File.dirname(__FILE__)+"/behaviortree.rb")

module BehaviorTree
  def self.parent=(value)
    TreeBuilder.parent = value
  end

  def self.build(rootnode=nil,&block)
    tree = TreeBuilder.new(rootnode)
    tree.instance_eval(&block) if block
    return tree.root
  end

  class TreeBuilder
    attr_reader :root, :children

    @@named_branches = {}

    def self.parent=(value)
      @@parent = value
    end

    def initialize(rootnode)
      @parent = @@parent

      @root = rootnode || BehaviorTree::Branch.new(:pass, :all)
    end

    def execute(&block)
      action { @parent.instance_eval(&block) }
    end

    def is?(&block)
      condition { @parent.instance_eval(&block) }
    end

    def branch(type, name=nil, &block)
      type_regex =
      /(?<result>pass|fail)
          _after_(
            (first_(?<children_result>pass|fail)) |
            (?<all>all)
          )
      /x
      if matches = type_regex.match(type) then
        exit_status_or_all = matches[:all] || matches[:children_result]
        node = BehaviorTree::Branch.new matches[:result].to_sym, exit_status_or_all.to_sym
        @@named_branches[name.to_sym] = node if name
      elsif type == :copy then
        node = @@named_branches[name.to_sym]
      end
      build_subtree node, &block

    end

    def copy_branch(name)
      node = @@named_branches[name.to_sym]
      build_subtree node
    end

    def build_subtree(node, &block)
      @root.add_child! node
      BehaviorTree.build(node, &block)
    end

    def method_missing(m, *args, &block)
      if @parent then
        action { @parent.send m, *args, &block }
      else
        super
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
