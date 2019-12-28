class AstNodeInfo
  @@indent_char = "  "
  
  attr_accessor :node, :text
  
  def initialize(node, text, indent = 0)
    @node = node
    @text = "#{@@indent_char * indent}#{text}"
  end
end
