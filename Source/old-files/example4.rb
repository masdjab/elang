=begin
AST node methods
:location, :loc, :assign_properties, :to_sexp_array, :to_sexp, :fancy_type, 
:append, :<<, :to_a, :hash, :concat, :children, :to_s, :type, :updated, :to_ast, 
:method, :singleton_method, :public_send, :extend, :to_enum, :enum_for, 
:display, :itself, :yield_self, :then
=end


class AstNodeInfo
  attr_accessor :text
  
  def initialize(text)
    @text = text
  end
end


class Compiler
  attr_reader :buffer
  
  private
  def initialize
    @buffer = []
    @indent_level = 0
    @indent_char = "  "
  end
  def alert(node, msg)
    raise \
      "Error at #{node.location.line}:#{node.location.column} => #{msg}\n" \
      "#{node.to_sexp_array.inspect}"
  end
  def indent
    @indent_level += 1
    yield
    @indent_level -= 1
  end
  def append_buffer(text = "")
    @buffer << "#{@indent_char * @indent_level}#{text}"
  end
  def handle_lvar(node)
    AstNodeInfo.new(node.children[0])
  end
  def handle_str(node)
    AstNodeInfo.new(node.children[0])
  end
  def handle_int(node)
    AstNodeInfo.new(node.children[0])
  end
  def handle_lvasgn(node)
    # ex1: [:lvasgn, :a, [:str, \"Hello world...\"]]
    # ex2: 
    #   [
    #     :masgn, 
    #     [:mlhs, [:lvasgn, :a], [:lvasgn, :b]], 
    #     [:array, [:lvar, :b], [:lvar, :a]]
    #   ]
    
    children = node.children
    receiver = children[0]
    
    if children.count == 1
      ast_info =  "#{receiver}"
    else
      source_info = handle_expression(children[1]).text
      ast_info = "#{receiver} = #{source_info.inspect}"
      append_buffer ast_info
    end
    
    AstNodeInfo.new(ast_info)
  end
  def handle_casgn(node)
    children = node.children
    unknown_item_1 = children[0]
    const_name = children[1]
    value_node = children[2]
    append_buffer "#{const_name} = #{handle_expression(value_node).text}"
  end
  def handle_expression(node)
    if node.type == :lvar
      handle_lvar node
    elsif node.type == :str
      handle_str node
    elsif node.type == :int
      handle_int node
    elsif node.type == :lvasgn
      handle_lvasgn node
    else
      alert node, "Unknown expression type: #{node.type.inspect}"
    end
  end
  def handle_method_params(node)
    AstNodeInfo.new(node.children.map{|c|c.children[0]}.join(", "))
  end
  def handle_send_params(nodes)
    if !nodes.nil?
      nodes = nodes.is_a?(Array) ? nodes : [nodes]
      AstNodeInfo.new(nodes.map{|x|handle_expression(x).text}.join(", "))
    else
      AstNodeInfo.new("")
    end
  end
  def handle_send(node)
    children = node.children
    receiver = children[0]
    command = children[1]
    param_nodes = children.length > 2 ? children[2..-1] : nil
    receiver_info = receiver ? "#{receiver}." : ""
    params_info = handle_send_params(param_nodes).text
    append_buffer "#{receiver_info}#{command}(#{params_info})"
  end
  def handle_array(node)
    AstNodeInfo.new(node.children.map{|x|handle_expression(x).text}.join(", "))
  end
  def handle_mlhs(node)
    # multiple left values
    # example: [:mlhs, [:lvasgn, :a], [:lvasgn, :b]]
    AstNodeInfo.new(node.children.map{|x|handle_expression(x).text}.join(", "))
    .tap{|x|puts "handle_mlhs => node: #{node.to_sexp_array.inspect}, ast_info: #{x.text}"}
  end
  def handle_masgn(node)
    # multiple assignment
    # example:
    #   [
    #    :masgn, 
    #    [:mlhs, [:lvasgn, :a], [:lvasgn, :b]], 
    #    [:array, [:lvar, :b], [:lvar, :a]]
    #   ]
    
    children = node.children
    values_node_1 = children[0]
    values_node_2 = children[1]
    append_buffer "#{handle_mlhs(values_node_1).text} = #{handle_array(values_node_2).text}".tap{|x|puts "masgn => #{x}"}
  end
  def handle_const(node)
    children = node.children
    unknown_item_1 = children[0]
    const_name = children[1]
    AstNodeInfo.new(const_name)
  end
  def handle_begin(node)
    # nothing to do
    compile node.children if !node.children.empty?
  end
  def handle_class(node)
    children = node.children
    name_node = children[0]
    unknown_node_1 = children[1]
    begin_node = children[2]
    
    if !name_node.type == :const
      alert node, "Class name must be a constant"
    else
      class_name = handle_const(name_node).text
      append_buffer "class #{class_name}"
      indent{handle_begin begin_node}
      append_buffer "end"
      append_buffer
    end
  end
  def handle_def(node)
    # example:
    #   [
    #     :def, 
    #     :method1, 
    #     [:args, [:arg, :a], [:arg, :b]], 
    #     (method body)
    #   ]
    
    children = node.children
    method_name = children[0]
    args_node = children[1]
    body_node = children[2]
    arg_names = handle_method_params(args_node).text
    append_buffer "def #{method_name}(#{arg_names})"
    indent{handle_node body_node}
    append_buffer "end"
    append_buffer
  end
  def handle_node(node)
    case node.type
    when :begin
      handle_begin node
    when :class
      handle_class node
    when :def
      handle_def node
    when :lvasgn
      handle_lvasgn node
    when :casgn
      handle_casgn node
    when :masgn
      handle_masgn node
    when :mlhs
      handle_mlhs node
    when :array
      handle_array node
    when :send
      handle_send node
    else
      alert node, "Unknown node type: #{node.type}"
    end
  end
  
  public
  def compile(node)
    if !node.is_a?(Array)
      handle_node node
    else
      node.each{|i|compile(i)}
    end
  end
end
