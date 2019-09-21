require 'parser/current'
require './scope'
require './identifier'
require './ast_node_dumper'

class Compiler
  attr_reader :asm_file
  
  private
  def initialize
    @source_file = ""
    @output_file = ""
    @scopes = []
    @identifiers = []
    @scope_stack = [nil]
    @cmd_flag = 0
  end
  def create_output_file_name(source_file)
    @source_file = File.basename(source_file)
    ext_name = File.extname(source_file)
    core_file_name = @source_file[0...-ext_name.length]
    @output_file = "#{core_file_name}.asm"
  end
  def alert(node, msg)
    raise "Error: #{msg}\n#{node.inspect}"
  end
  def load_libraries
    #
  end
  def handle_ivar(node)
    node.children[0]
  end
  def handle_lvar(node)
    node.children[0]
  end
  def handle_str(node)
    node.children[0].inspect
  end
  def handle_int(node)
    node.children[0]
  end
  def handle_sym(node)
    node.children[0].inspect
  end
  def handle_lvasgn(node)
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
      receiver
    elsif children.count == 2
      source_info = handle_node(children[1])
      "lvasgn(#{receiver}, #{source_info})"
    end
  end
  def handle_casgn(node)
    # ex1: [:casgn, nil, :HEAP_OFFSET, [:int, 512]]
    children = node.children
    scope = children[0]
    const_name = children[1]
    value_node = children[2]
    "const #{scope.inspect}, #{const_name}, #{handle_node(value_node)}"
  end
  def handle_ivasgn(node)
    # ex1: [:ivasgn, :@indent_level]
    # ex2: [:ivasgn, :@text, [:lvar, :text]]
    
    children = node.children
    var_name = children[0]
    
    if children.count == 1
      var_name
    else
      "ivasgn(#{var_name}, #{handle_node(children[1])})"
    end
  end
  def handle_array(node)
    if node.children.empty?
      "[]"
    else
      node.children.map{|x|handle_node(x)}.join(", ")
    end
  end
  def handle_mlhs(node)
    # multiple left values
    # example: [:mlhs, [:lvasgn, :a], [:lvasgn, :b]]
    node.children.map{|x|handle_node(x)}.join(", ")
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
    "#{handle_mlhs(values_node_1)} = #{handle_array(values_node_2)}"
  end
  def handle_const(node)
    children = node.children
    unknown_item_1 = children[0]
    children[1]
  end
  def handle_dstr(node)
    "(dstr)"
  end
  def handle_op_asgn(node)
    # ex1: [:op_asgn, [:ivasgn, :@indent_level], :+, [:int, 1]]
    # ex2: [:op_asgn, [:ivasgn, :@indent_level], :-, [:int, 1]]
    children = node.children
    v1_text = handle_node(children[0])
    v2_text = handle_node(children[2])
    "#{v1_text} = #{v1_text} #{children[1]} #{v2_text}"
  end
  def handle_if(node)
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
    
    #"(if)"
  end
  def handle_yield(node)
    # ex1: yield
    "yield"
  end
  def handle_index(node)
    # ex1: [:index, [:send, [:lvar, :node], :children], [:int, 0]]
    
    children = node.children
    receiver_node = children[0]
    params_node = children[1]
    
    receiver_text = handle_node(receiver_node)
    params_text = handle_node(params_node)
    
    "index(#{receiver_text}, #{params_text})"
  end
  def handle_method_params(node)
    node.children.map{|c|c.children[0]}.join(", ")
  end
  def handle_send_params(nodes)
    #if !nodes.nil?
      nodes = nodes.is_a?(Array) ? nodes : [nodes]
      nodes.map{|x|handle_node(x)}.join(", ")
    #else
    #  ""
    #end
  end
  def handle_send(node)
    children = node.children
    receiver_node = children[0]
    command_node = children[1]
    param_nodes = children.length > 2 ? children[2..-1] : nil
    
    receiver_text = receiver_node ? handle_node(receiver_node) : "nil"
    command_text = command_node
    params_list = param_nodes ? ", #{handle_send_params(param_nodes)}" : ""
    
    "send(#{receiver_text}, #{command_text}#{params_list})"
  end
  def handle_block(node)
    "(block)"
  end
  def handle_case(node)
    "(case)"
  end
  def handle_begin(node)
    if !node.nil? && !node.children.empty?
      node.children.map{|x|handle_node(x)}.join
    else
      ""
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
    
    @cmd_flag = 0
    arg_names = handle_method_params(args_node)
    @cmd_flag = 0
    
    c1 = "def #{method_name}#{arg_names.empty? ? "" : "(#{arg_names})"}"
    c2 = handle_node(body_node)
    
    "#{c1}\n#{c2}end def"
  end
  def handle_class(node)
    children = node.children
    name_node = children[0]
    unknown_node_1 = children[1]
    body_node = children[2]
    
    if !name_node.type == :const
      alert node, "Class name must be a constant"
    else
      module_name = name_node.children[0]
      class_name = name_node.children[1]
      @scopes << (scope = Scope.new(module_name, class_name, :class))
      @scope_stack << scope
      
      @cmd_flag = 0
      node_code = handle_node(body_node)
      @cmd_flag = 0
      
      @scope_stack.pop
      
      code_array = 
        [
          "class #{module_name ? module_name : "nil"}, :#{class_name}, nil\n", 
          node_code, 
          "end class\n"
        ]
      
      code_array.join
    end
  end
  def handle_node(node)
    # if node.nil?
    #   ""
    # elsif node.is_a?(Symbol)
    #   node.inspect
    if node.is_a?(Array)
      node.map{|x|handle_node(x)}.join
    else
      case node.type
      when :array
        handler = method(:handle_array)
      when :begin
        handler = method(:handle_begin)
      when :block
        handler = method(:handle_block)
      when :case
        handler = method(:handle_case)
      when :casgn
        handler = method(:handle_casgn)
      when :class
        handler = method(:handle_class)
      when :const
        handler = method(:handle_const)
      when :def
        handler = method(:handle_def)
      when :dstr
        handler = method(:handle_dstr)
      when :if
        handler = method(:handle_if)
      when :index
        handler = method(:handle_index)
      when :int
        handler = method(:handle_int)
      when :ivar
        handler = method(:handle_ivar)
      when :ivasgn
        handler = method(:handle_ivasgn)
      when :lvasgn
        handler = method(:handle_lvasgn)
      when :lvar
        handler = method(:handle_lvar)
      when :masgn
        handler = method(:handle_masgn)
      when :mlhs
        handler = method(:handle_mlhs)
      when :op_asgn
        handler = method(:handle_op_asgn)
      when :send
        handler = method(:handle_send)
      when :str
        handler = method(:handle_str)
      when :sym
        handler = method(:handle_sym)
      when :yield
        handler = method(:handle_yield)
      else
        handler = nil
      end
      
      if handler
        if (@cmd_flag == 0) && ![:begin].include?(node.type)
          @cmd_flag = 1
          code = "#{handler.call(node)}\n"
          @cmd_flag = 0
        else
          code = handler.call node
        end
      else
        alert node, "Unknown node type: #{node.type.inspect}"
      end
    end
    
    code
  end
  
  public
  def compile(source_file)
    Parser::Builders::Default.emit_lambda   = true
    Parser::Builders::Default.emit_procarg0 = true
    Parser::Builders::Default.emit_encoding = true
    Parser::Builders::Default.emit_index    = true
    
    create_output_file_name source_file
    
    load_libraries
    source_code = File.read(source_file)
    ast_nodes = Parser::CurrentRuby.parse(source_code)
    puts ast_nodes.to_sexp_array.inspect
    puts
    
    output = handle_node(ast_nodes)
    output.gsub!("\n\n", "\n")
    File.write(@output_file, output)
    
    puts File.read(@output_file)
    puts
    puts "source_file: #{@source_file}"
    puts "output_file: #{@output_file}"
  end
end

Compiler.new.compile(ARGV[0])
