=begin
AST node methods
:location, :loc, :assign_properties, :to_sexp_array, :to_sexp, :fancy_type, 
:append, :<<, :to_a, :hash, :concat, :children, :to_s, :type, :updated, :to_ast, 
:method, :singleton_method, :public_send, :extend, :to_enum, :enum_for, 
:display, :itself, :yield_self, :then
=end


class AstNodeInfo
  @@indent_char = "  "
  
  attr_accessor :node, :text
  
  def initialize(node, text, indent = 0)
    @node = node
    @text = "#{@@indent_char * indent}#{text}"
  end
end


class Compiler
  attr_reader :buffer
  
  private
  def alert(node, msg)
    raise \
      "Error at #{node.location.line}:#{node.location.column} => #{msg}\n" \
      "#{node.to_sexp_array.inspect}"
  end
  def handle_lvar(node, ind = 0)
    AstNodeInfo.new(node, node.children[0], ind)
  end
  def handle_str(node, ind = 0)
    AstNodeInfo.new(node, node.children[0].inspect, ind)
  end
  def handle_int(node, ind = 0)
    AstNodeInfo.new(node, node.children[0], ind)
  end
  def handle_sym(node, ind = 0)
    AstNodeInfo.new(node, node.children[0].inspect, ind)
  end
  def handle_lvasgn(node, ind = 0)
    # ex1: [:lvasgn, :a, [:str, \"Hello world...\"]]
    # ex2: 
    #   [
    #     :masgn, 
    #     [:mlhs, [:lvasgn, :a], [:lvasgn, :b]], 
    #     [:array, [:lvar, :b], [:lvar, :a]]
    #   ]
    # ex3: 
    #   [:lvasgn, :children, [:send, [:lvar, :node], :children]]
    
    # puts "lvasgn => node: #{node.to_sexp_array.inspect}"
    
    children = node.children
    receiver = children[0]
    
    if children.count == 1
      ast_info =  "#{receiver}"
    elsif children.count == 2
      source_info = handle_node(children[1]).text
      ast_info = "#{receiver} = #{source_info}"
    end
    
    AstNodeInfo.new(node, ast_info, ind)
  end
  def handle_casgn(node, ind = 0)
    children = node.children
    unknown_item_1 = children[0]
    const_name = children[1]
    value_node = children[2]
    AstNodeInfo.new(node, "#{const_name} = #{handle_node(value_node, 0).text}", ind)
  end
  def handle_ivasgn(node, ind = 0)
    # ex1: [:ivasgn, :@indent_level]
    # ex2: [:ivasgn, :@text, [:lvar, :text]]
    
    children = node.children
    var_name = children[0]
    
    if children.count == 1
      AstNodeInfo.new(node, var_name, ind)
    else
      AstNodeInfo.new(node, "#{var_name} = #{handle_node(children[1]).text}", ind)
    end
  end
  def handle_array(node, ind = 0)
    if node.children.empty?
      AstNodeInfo.new(node, "[]", 0)
    else
      AstNodeInfo.new(node, node.children.map{|x|handle_node(x).text}.join(", "), ind)
    end
  end
  def handle_mlhs(node, ind = 0)
    # multiple left values
    # example: [:mlhs, [:lvasgn, :a], [:lvasgn, :b]]
    AstNodeInfo.new(node, node.children.map{|x|handle_node(x).text}.join(", "), ind)
  end
  def handle_masgn(node, ind = 0)
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
    AstNodeInfo.new(node, "#{handle_mlhs(values_node_1).text} = #{handle_array(values_node_2).text}", ind)
  end
  def handle_const(node, ind = 0)
    children = node.children
    unknown_item_1 = children[0]
    const_name = children[1]
    AstNodeInfo.new(node, const_name, ind)
  end
  def handle_dstr(node, ind = 0)
    AstNodeInfo.new(node, "(dstr)", ind)
  end
  def handle_op_asgn(node, ind = 0)
    # ex1: [:op_asgn, [:ivasgn, :@indent_level], :+, [:int, 1]]
    # ex2: [:op_asgn, [:ivasgn, :@indent_level], :-, [:int, 1]]
    children = node.children
    v1_text = handle_node(children[0], 0).text
    v2_text = handle_node(children[2], 0).text
    AstNodeInfo.new(node, "#{v1_text} = #{v1_text} #{children[1]} #{v2_text}", ind)
  end
  def handle_if(node, ind = 0)
    # ex1:
    #   [
    #     :if, 
    #     [:send, [:send, nil, :a], :==, [:int, 1]], 
    #     (body), 
    #     [
    #       :if, 
    #       [:send, [:send, nil, :a], :==, [:int, 2]], 
    #       (body1), 
    #       (body2)
    #     ]
    #   ]
    # ex2: 
    #   [
    #     :if, 
    #     [:send, [:send, [:lvar, :children], :count], :==, [:int, 1]], (body), 
    #     [:begin, (body)]
    #   ]
    
    #AstNodeInfo.new(node, "(if)", ind)
  end
  def handle_yield(node, ind = 0)
    # ex1: yield
    AstNodeInfo.new(node, "yield", ind)
  end
  def handle_index(node, ind = 0)
    # ex1: [:index, [:send, [:lvar, :node], :children], [:int, 0]]
    
    children = node.children
    receiver_node = children[0]
    params_node = children[1]
    
    receiver_text = handle_node(receiver_node).text
    params_text = handle_node(params_node).text
    
    AstNodeInfo.new(node, "#{receiver_text}[#{params_text}]", ind)
  end
  def handle_method_params(node, ind = 0)
    AstNodeInfo.new(node, node.children.map{|c|c.children[0]}.join(", "), 0)
  end
  def handle_send_params(nodes, ind = 0)
    #if !nodes.nil?
      nodes = nodes.is_a?(Array) ? nodes : [nodes]
      AstNodeInfo.new(nodes, nodes.map{|x|handle_node(x).text}.join(", "), ind)
    #else
    #  AstNodeInfo.new(nodes, "", ind)
    #end
  end
  def handle_send(node, ind = 0)
    # puts "handle send => node: #{node.to_sexp_array.inspect}"
    children = node.children
    receiver_node = children[0]
    command = children[1]
    param_nodes = children.length > 2 ? children[2..-1] : nil
    
    receiver_text = receiver_node ? handle_node(receiver_node).text : ""
    receiver_info = !receiver_text.empty? ? "#{receiver_text}." : ""
    params_list = param_nodes ? handle_send_params(param_nodes).text : ""
    params_info = params_list.empty? ? "" : "(#{params_list})"
    AstNodeInfo.new(node, "#{receiver_info}#{command}#{params_info}", ind)
  end
  def handle_block(node, ind = 0)
    AstNodeInfo.new(node, "(block)", ind)
  end
  def handle_case(node, ind = 0)
    AstNodeInfo.new(node, "(case)", ind)
  end
  def handle_begin(node, ind = 0)
    if !node.nil? && !node.children.empty?
      AstNodeInfo.new(node, node.children.map{|x|handle_node(x, ind).text}.join("\n"), 0)
    else
      AstNodeInfo.new(node, "", ind)
    end
  end
  def handle_def(node, ind = 0)
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
    
    node_info_array = 
      [
        AstNodeInfo.new(nil, "def #{method_name}#{arg_names.empty? ? "" : "(#{arg_names})"}", ind).text, 
        handle_node(body_node, ind + 1).text, 
        AstNodeInfo.new(nil, "end", ind).text
      ]
    
    AstNodeInfo.new(node, node_info_array.join("\n"), 0)
  end
  def handle_class(node, ind = 0)
    children = node.children
    name_node = children[0]
    unknown_node_1 = children[1]
    body_node = children[2]
    
    if !name_node.type == :const
      alert node, "Class name must be a constant"
    else
      node_info_array = 
        [
          AstNodeInfo.new(nil, "class #{handle_const(name_node, 0).text}", ind).text, 
          handle_node(body_node, ind + 1).text, 
          AstNodeInfo.new(nil, "end", ind).text
        ]
      
      AstNodeInfo.new(node, node_info_array.join("\n"), 0)
    end
  end
  def handle_node(node, ind = 0)
    if node.nil?
      AstNodeInfo.new(node, "", 0)
    # elsif node.is_a?(Symbol)
    #   AstNodeInfo.new(node, node.inspect, 0)
    elsif node.is_a?(Array)
      AstNodeInfo.new(node.map{|x|handle_node(x, ind)}.join("\n"), ind)
    else
      case node.type
      when :array
        handle_array node, ind
      when :begin
        handle_begin node, ind
      when :block
        handle_block node, ind
      when :case
        handle_case node, ind
      when :casgn
        handle_casgn node, ind
      when :class
        handle_class node, ind
      when :const
        handle_const node, ind
      when :def
        handle_def node, ind
      when :dstr
        handle_dstr node, ind
      when :if
        handle_if node, ind
      when :index
        handle_index node, ind
      when :int
        handle_int node, ind
      when :ivasgn
        handle_ivasgn node, ind
      when :lvasgn
        handle_lvasgn node, ind
      when :lvar
        handle_lvar node, ind
      when :masgn
        handle_masgn node, ind
      when :mlhs
        handle_mlhs node, ind
      when :op_asgn
        handle_op_asgn node, ind
      when :send
        handle_send node, ind
      when :str
        handle_str node, ind
      when :sym
        handle_sym node, ind
      when :yield
        handle_yield node, ind
      else
        alert node, "Unknown node type: #{node.type}"
      end
    end
  end
  
  public
  def compile(node)
    handle_node(node).text
  end
end
