class AstNodeDumper
  def initialize
    @indent_level = 0
    @indent_char = " "
  end
  def indent
    @indent_level += 1
    yield
    @indent_level -= 1
  end
  def format(text)
    "#{@indent_char * @indent_level}#{text}"
  end
  def dump_nodes(nodes, &block)
    if nodes.is_a?(Array)
      nodes.each{|nx|dump_nodes(nx, &block)}
    else
      if nodes.is_a?(Parser::AST::Node)
        yield format "*#{nodes.type.inspect} (#{nodes.children.count} children)"
      elsif nodes.nil?
        yield format "nil"
      elsif ["Symbol", "Integer", "String"].include?(nodes.class.to_s)
        yield format nodes.inspect
      else
        yield format "#{nodes.class}"
      end
      
      if nodes.respond_to?(:children) && !nodes.children.empty?
        indent{dump_nodes nodes.children, &block}
      end
    end
  end
end
