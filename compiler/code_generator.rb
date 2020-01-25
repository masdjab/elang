require './compiler/constant'
require './compiler/class'
require './compiler/function'
require './compiler/system_function'
require './compiler/function_parameter'
require './compiler/variable'
require './compiler/instance_variable'
require './compiler/class_variable'
require './compiler/class_function'
require './compiler/scope'
require './compiler/symbol_ref'
require './compiler/ast_node'
require './compiler/codeset'
require './utils/converter'


module Elang
  class CodeGenerator
    SYS_FUNCTIONS = 
      {
        :plus         => SystemFunction.new("[int_add]"), 
        :minus        => SystemFunction.new("[int_subtract]"), 
        :star         => SystemFunction.new("[int_multiply]"), 
        :slash        => SystemFunction.new("[int_divide]"), 
        :and          => SystemFunction.new("[int_and]"), 
        :or           => SystemFunction.new("[int_or]"), 
        :get_obj_var  => SystemFunction.new("[get_obj_var]"), 
        :set_obj_var  => SystemFunction.new("[set_obj_var]")
      }
    
    attr_reader :symbols, :symbol_refs
    
    private
    def initialize
      @codeset = CodeSet.new
      @scope_stack = []
    end
    def code_len
      @codeset.code_branch.length
    end
    def hex2bin(h)
      Elang::Utils::Converter.hex_to_bin(h)
    end
    def make_int(value)
      (value << 1) | (value < 0 ? 0x8000 : 0) | 1
    end
    def current_scope
      !@scope_stack.empty? ? @scope_stack.last : Scope.new
    end
    def enter_scope(scope)
      @scope_stack << scope
      @codeset.enter_subs
    end
    def leave_scope
      @codeset.leave_subs
      @scope_stack.pop if !@scope_stack.empty?
    end
    def code_type
      !current_scope.to_s.empty? ? :subs : :main
    end
    def add_constant_ref(symbol, location)
      @codeset.symbol_refs << ConstantRef.new(symbol, current_scope, location, code_type)
    end
    def add_variable_ref(symbol, location)
      @codeset.symbol_refs << VariableRef.new(symbol, current_scope, location, code_type)
    end
    def add_function_ref(symbol, location)
      @codeset.symbol_refs << FunctionRef.new(symbol, current_scope, location, code_type)
    end
    def get_string_constant(str)
      if (symbol = @codeset.symbols.find_str(str)).nil?
        symbol = Elang::Constant.new(current_scope, Elang::Constant.generate_name, str)
      end
      
      symbol
    end
    def append_code(code)
      @codeset.append_code code
    end
    def intobj(value)
      (value << 1) | 1
    end
    def invoke_num_method(meth_name)
      add_function_ref SYS_FUNCTIONS[meth_name], code_len + 1
      append_code hex2bin("E80000")
    end
    def register_local_variable(name)
      receiver = Elang::Variable.new(current_scope, name)
      @codeset.symbols.add receiver
      receiver
    end
    def register_instance_variable(name)
      receiver = InstanceVariable.new(current_scope, name)
      @codeset.symbols.add receiver
      receiver
    end
    def register_class_variable(name)
      receiver = ClassVariable.new(current_scope, name)
      @codeset.symbols.add receiver
      receiver
    end
    def get_number(number)
      # mov ax, imm
      value_hex = Elang::Utils::Converter.int_to_whex_be(make_int(number)).upcase
      append_code hex2bin("B8" + value_hex)
    end
    def get_string_object(name)
      # mov reg, str
      str = get_string_constant(node.text)
      add_constant_ref str, code_len + 1
      append_code hex2bin("A10000")
    end
    def get_variable(name)
      if (symbol = @codeset.symbols.find_nearest(active_scope = current_scope, name)).nil?
        raise "Cannot get value from '#{name}' , symbol not defined in scope '#{active_scope.to_s}'"
      elsif symbol.is_a?(FunctionParameter)
        # mov ax, [bp - n]
        add_variable_ref symbol, code_len + 2
        append_code hex2bin("8B4600")
      elsif symbol.is_a?(InstanceVariable)
        # #(todo)#resolve object id, class id, and instance variable getter address
        if active_scope.cls.nil?
          raise "Instance variable '#{name}' accessed in scope '#{active_scope.to_s}' which is not instance method"
        elsif (cls = @codeset.symbols.find_exact(Scope.new, active_scope.cls)).nil?
          raise "Class #{active_scope.cls} is not defined"
        else
          add_variable_ref symbol, code_len + 1
          add_variable_ref cls, code_len + 5
          add_function_ref SYS_FUNCTIONS[:get_obj_var], code_len + 9
          append_code hex2bin("B8000050B8000050E80000")
        end
      elsif symbol.is_a?(ClassVariable)
        # #(todo)#fix binary command
        append_code hex2bin("A40000")
      elsif symbol.scope.root?
        # mov var, ax
        add_variable_ref symbol, code_len + 1
        append_code hex2bin("A10000")
      elsif symbol.is_a?(Variable)
        # mov ax, [bp + n]
        add_variable_ref symbol, code_len + 2
        append_code hex2bin("8B4600")
      else
        raise "Cannot get value from '#{name}', symbol type '#{symbol.class}' unknown"
      end
    end
    def set_variable(name)
      if (symbol = @codeset.symbols.find_nearest(active_scope = current_scope, name)).nil?
        raise "Cannot set value to '#{name}' , symbol not defined in scope '#{active_scope.to_s}'"
      elsif symbol.is_a?(FunctionParameter)
        # mov [bp - n], ax
        add_variable_ref symbol, code_len + 2
        append_code hex2bin("894600")
      elsif symbol.is_a?(InstanceVariable)
        # #(todo)#fix binary command
        if active_scope.cls.nil?
          raise "Attempted to write to instance variable '#{name}' in scope '#{active_scope.to_s}' which is not instance method"
        elsif (cls = @codeset.symbols.find_exact(Scope.new, active_scope.cls)).nil?
          raise "Class #{active_scope.cls} is not defined"
        else
          add_variable_ref symbol, code_len + 1
          add_variable_ref cls, code_len + 5
          add_function_ref SYS_FUNCTIONS[:set_obj_var], code_len + 10
          append_code hex2bin("50B8000050B8000050E80000")
        end
      elsif symbol.is_a?(ClassVariable)
        ## #(todo)#fix binary command
        append_code hex2bin("A70000")
      elsif symbol.scope.root?
        # mov var, ax
        add_variable_ref symbol, code_len + 1
        append_code hex2bin("A30000")
      elsif symbol.is_a?(Variable)
        # mov [bp + n], ax
        add_variable_ref symbol, code_len + 2
        append_code hex2bin("894600")
      else
        raise "Cannot set value to '#{name}', symbol type '#{symbol.class}' unknown"
      end
    end
    def prepare_operand(node)
      active_scope = current_scope
      
      if node.is_a?(Array)
        handle_any([node])
      elsif node.type == :number
        get_number node.text.to_i
      elsif node.type == :string
        get_string_object node.text
      else
        get_variable node.text
      end
    end
    def prepare_arguments(arguments)
      (0...arguments.count).map{|x|x}.reverse.each do |i|
        prepare_operand arguments[i]
        append_code hex2bin("50")
      end
    end
    def handle_expression(node)
      prepare_operand node[2]
      append_code hex2bin("50")
      prepare_operand node[1]
      append_code hex2bin("50")
      invoke_num_method node[0].type
    end
    def handle_assignment(node)
      left_var = node[1]
      var_name = left_var.text
      active_scope = current_scope
      
      if !left_var.is_a?(Elang::AstNode) || (left_var.type != :identifier)
        raise "Left operand for assignment must be a symbol, #{left_var.inspect} given"
      end
      
      if (receiver = @codeset.symbols.find_nearest(active_scope, var_name)).nil?
        if var_name.index("@@") == 0
          # #(todo)#class variable
          receiver = register_class_variable(var_name)
        elsif var_name.index("@") == 0
          # instance variable
          receiver = register_instance_variable(var_name)
        else
          # local variable
          receiver = register_local_variable(var_name)
        end
      end
      
      prepare_operand node[2]
      set_variable var_name
    end
    def handle_function_def(node)
      active_scope = current_scope
      
      rcvr_name = node[1] ? node[1].text : active_scope.cls
      func_name = node[2].text
      func_args = node[3]
      func_body = node[4]
      
      #(todo)#count variable_count
      function = @codeset.symbols.find_exact(active_scope, func_name)
      function.offset = code_len
      variable_count = 0
      params_count = func_args.count + (rcvr_name ? 2 : 0)
      
      enter_scope Scope.new(active_scope.cls, func_name)
      
      # push bp; mov bp, sp
      append_code hex2bin("55" + "89E5")
      
      if variable_count > 0
        # sub sp, nn
        append_code hex2bin("81EC" + Elang::Utils::Converter.int_to_whex_be(variable_count * 2))
      end
      
      handle_any func_body
      
      if variable_count > 0
        # add sp, nn
        append_code hex2bin("81C4" + Elang::Utils::Converter.int_to_whex_be(variable_count * 2))
      end
      
      # pop bp
      append_code hex2bin("5D")
      
      # ret [n]
      hex_code = (params_count > 0 ? "C2#{Elang::Utils::Converter.int_to_whex_be(params_count * 2).upcase}" : "C3")
      append_code hex2bin(hex_code)
      leave_scope
    end
    def handle_function_call(node)
      # push ax; call target
      func_name = node[0].text
      
      if (function = @codeset.symbols.find_function(func_name)).nil?
        raise "Call to undefined function '#{func_name}'"
      else
        prepare_arguments node[1]
        add_function_ref function, code_len + 1
        append_code hex2bin("E80000")
      end
    end
    def handle_send(node)
      # [., receiver, name, args]
      
      active_scope = current_scope
      rcvr_name = node[1] ? node[1].text : nil
      func_name = node[2].text
      func_args = node[3]
      
      prepare_arguments func_args
      append_code hex2bin("B8000050A1000050")
      append_code hex2bin("E80000")
    end
    def handle_class_def(nodes)
      cls_name = nodes[1].text
      cls_prnt = nodes[2] ? nodes[2].text : nil
      
      enter_scope Scope.new(cls_name)
      handle_any nodes[3]
      leave_scope
    end
    def handle_any(nodes)
      nodes.each do |node|
        if node.is_a?(Array)
          if !(first_node = node[0]).is_a?(Elang::AstNode)
            raise "Expected identifier, #{node[0].inspect} given"
          else
            case first_node.type
            when :assign
              handle_assignment node
            when :plus, :minus, :star, :slash, :and, :or
              handle_expression node
            when :dot
              handle_send node
            when :identifier
              if first_node.text == "def"
                handle_function_def node
              elsif first_node.text == "class"
                handle_class_def node
              elsif first_node.text.index("@@")
                register_class_variable first_node.text
                get_variable first_node.text
              elsif first_node.text.index("@")
                register_instance_variable first_node.text
                get_variable first_node.text
              else
                if (function = @codeset.symbols.find_nearest(current_scope, first_node.text)).nil?
                  raise "Call to undefined function '#{first_node.text}' from scope '#{current_scope.to_s}'"
                elsif !function.is_a?(Function)
                  raise "Call to non-function '#{first_node.text}'"
                else
                  handle_function_call node
                end
              end
            else
              raise "Unexpected node type #{first_node.type.inspect} in #{first_node.inspect}"
            end
          end
        else
          raise "Expected array, #{node.class} given: #{node.inspect}"
        end
      end
    end
    def detect_names(nodes)
      nodes.each do |node|
        if node.is_a?(Array)
          if (first_node = node[0]).is_a?(Array)
            raise "This branch is not expected to be executed"
            detect_names first_node
          elsif first_node.type == :identifier
            if first_node.text == "def"
              active_scope = current_scope
              rcvr_name = node[1] ? node[1].text : nil
              func_name = node[2].text
              func_args = node[3]
              func_body = node[4]
              function = Function.new(active_scope, rcvr_name, func_name, func_args, 0)
              
              if !active_scope.fun.nil?
                raise "Function cannot be nested"
              else
                @codeset.symbols.add function
                enter_scope Scope.new(active_scope.cls, func_name)
                
                (0...func_args.count).each do |i|
                  param = FunctionParameter.new(current_scope, func_args[i].text, i)
                  @codeset.symbols.add param
                end
                
                detect_names func_body
                leave_scope
              end
            elsif first_node.text == "class"
              cls_name = node[1].text
              cls_parent = node[2] ? node[2].text : nil
              cls_body = node[3]
              
              if !(active_scope = current_scope).cls.nil?
                raise "Class cannot be nested"
              else
                cls_object = Class.new(active_scope, cls_name, cls_parent)
                @codeset.symbols.add cls_object
                enter_scope Scope.new(cls_name)
                detect_names cls_body
                leave_scope
              end
            end
          end
        end
      end
    end
    
    public
    def generate_code(nodes)
      @scope_stack = []
      @scope_stack = []
      @codeset = CodeSet.new
      detect_names nodes
      handle_any nodes
      @codeset
    end
  end
end
