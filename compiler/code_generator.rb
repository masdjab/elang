require './compiler/constant'
require './compiler/class'
require './compiler/function'
require './compiler/system_function'
require './compiler/function_parameter'
require './compiler/function_id'
require './compiler/variable'
require './compiler/instance_variable'
require './compiler/class_variable'
require './compiler/class_function'
require './compiler/scope'
require './compiler/symbol_ref'
require './compiler/ast_node'
require './compiler/codeset'
require './compiler/codeset_tool'
require './utils/converter'


module Elang
  class CodeGenerator
    SYS_FUNCTIONS = 
      {
        :_int_pack            => SystemFunction.new("_int_pack"), 
        :_int_unpack          => SystemFunction.new("_int_unpack"), 
        :plus                 => SystemFunction.new("_int_add"), 
        :minus                => SystemFunction.new("_int_subtract"), 
        :star                 => SystemFunction.new("_int_multiply"), 
        :slash                => SystemFunction.new("_int_divide"), 
        :and                  => SystemFunction.new("_int_and"), 
        :or                   => SystemFunction.new("_int_or"), 
        :get_obj_var          => SystemFunction.new("_get_obj_var"), 
        :set_obj_var          => SystemFunction.new("_set_obj_var"), 
        :send_to_obj          => SystemFunction.new("_send_to_object"), 
        :mem_block_init       => SystemFunction.new("mem_block_init"), 
        :mem_alloc            => SystemFunction.new("mem_alloc"), 
        :mem_dealloc          => SystemFunction.new("mem_dealloc"), 
        :mem_get_data_offset  => SystemFunction.new("mem_get_data_offset"), 
        :alloc_object         => SystemFunction.new("alloc_object")
      }
      
    SYS_VARIABLES = ["first_block", "dynamic_area"]
    
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
    def intobj(value)
      (value << 1) | 1
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
    def add_function_id_ref(symbol, location)
      @codeset.symbol_refs << FunctionIdRef.new(symbol, current_scope, location, code_type)
    end
    def append_code(code)
      @codeset.append_code code
    end
    def define_system_variables
      scope = Scope.new
      SYS_VARIABLES.each{|n|@codeset.symbols.add Variable.new(scope, n)}
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
      scope = Scope.new(current_scope.cls)
      ivars = @codeset.symbols.items.select{|x|(x.scope.cls == scope.cls) && x.is_a?(InstanceVariable)}
      
      if (receiver = ivars.find{|x|x.name == name}).nil?
        index = ivars.inject(0){|a,b|b.index >= a ? b.index + 1 : a}
        receiver = InstanceVariable.new(scope, name, index)
        @codeset.symbols.add receiver
      end
      
      receiver
    end
    def register_class(name, parent)
      scope = Scope.new
      clist = @codeset.symbols.items.select{|x|x.is_a?(Class)}
      
      if (cls = clist.find{|x|x.name == name}).nil?
        idx = clist.inject(0){|a,b|b.index >= a ? b.index + 1 : a}
        @codeset.symbols.add(cls = Class.new(scope, name, parent, idx))
      end
      
      cls
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
    def get_string_object(text)
      if (symbol = @codeset.symbols.find_string(text)).nil?
        symbol = Elang::Constant.new(current_scope, Elang::Constant.generate_name, text)
        @codeset.symbols.add symbol
      end
      
      add_constant_ref symbol, code_len + 1
      # mov reg, symbol
      append_code hex2bin("A10000")
    end
    def get_variable(name)
      active_scope = current_scope
      
      if name == "nil"
        append_code hex2bin("B80000")
      elsif (symbol = @codeset.symbols.find_nearest(active_scope, name)).nil?
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
          add_function_ref SYS_FUNCTIONS[:get_obj_var], code_len + 9
          append_code hex2bin("B80000508B460450E80000")
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
          add_variable_ref symbol, code_len + 2
          add_function_ref SYS_FUNCTIONS[:set_obj_var], code_len + 10
          append_code hex2bin("50B80000508B460450E80000")
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
      if node.is_a?(Array)
        if node.count > 1
          prepare_operand node[2]
          append_code hex2bin("50")
          prepare_operand node[1]
          append_code hex2bin("50")
          invoke_num_method node[0].type
        else
          prepare_operand node[0]
        end
      else
        prepare_operand node
      end
    end
    def handle_assignment(node)
      prepare_operand node[2]
      set_variable node[1].text
    end
    def handle_function_def(node)
      active_scope = current_scope
      
      rcvr_name = node[1] ? node[1].text : active_scope.cls
      func_name = node[2].text
      func_args = node[3]
      func_body = node[4]
      
      #(todo)#count variable_count
      enter_scope Scope.new(active_scope.cls, func_name)
      
      function = @codeset.symbols.find_exact(active_scope, func_name)
      function.offset = code_len
      variable_count = 0
      params_count = func_args.count + (rcvr_name ? 2 : 0)
      
      if active_scope.cls.nil?
        # push bp; mov bp, sp
        append_code hex2bin("55" + "89E5")
      end
      
      if variable_count > 0
        # sub sp, nn
        append_code hex2bin("81EC" + Elang::Utils::Converter.int_to_whex_be(variable_count * 2))
      end
      
      handle_any func_body
      
      if variable_count > 0
        # add sp, nn
        append_code hex2bin("81C4" + Elang::Utils::Converter.int_to_whex_be(variable_count * 2))
      end
      
      if active_scope.cls.nil?
        # pop bp
        append_code hex2bin("5D")
        
        # ret [n]
        hex_code = (params_count > 0 ? "C2#{Elang::Utils::Converter.int_to_whex_be(params_count * 2).upcase}" : "C3")
        append_code hex2bin(hex_code)
      else
        append_code hex2bin("C3")
      end
      
      leave_scope
    end
    def handle_function_call(node)
      func_name = node[0].text
      
      if SYS_FUNCTIONS.key?(func_name.to_sym)
        prepare_arguments node[1]
        add_function_ref SystemFunction.new(func_name.to_sym), code_len + 1
        append_code hex2bin("E80000")
      elsif function = @codeset.symbols.find_function(func_name)
        prepare_arguments node[1]
        add_function_ref function, code_len + 1
        append_code hex2bin("E80000")
      else
        raise "Call to undefined function '#{func_name}'"
      end
    end
    def handle_send(node)
      # [., receiver, name, args]
      
      active_scope = current_scope
      rcvr_name = node[1] ? node[1].text : nil
      func_name = node[2].text
      func_args = node[3] ? node[3] : []
      
      if func_name == "new"
        if (cls = @codeset.symbols.items.find{|x|x.is_a?(Class) && (x.name == rcvr_name)}).nil?
          raise "Class '#{rcvr_name}' not defined"
        else
          ct = CodesetTool.new(@codeset)
          iv = ct.get_instance_variables(cls)
          sz = Utils::Converter.int_to_whex_rev(iv.count)
          ci = Utils::Converter.int_to_whex_rev(CodesetTool.create_class_id(cls))
          fb = @codeset.symbols.find_nearest(active_scope, "first_block")
          hc = "B8#{sz}50B8#{ci}50A1000050E80000"
          add_variable_ref fb, code_len + 9
          add_function_ref SYS_FUNCTIONS[:alloc_object], code_len + 13
          append_code hex2bin(hc)
        end
      else
        prepare_arguments func_args
        
        #push args count
        append_code hex2bin("B8" + Utils::Converter.int_to_whex_rev(func_args.count) + "50")
        
        #(todo)#push object method id
        function_id = FunctionId.new(current_scope, func_name)
        add_function_id_ref function_id, code_len + 1
        append_code hex2bin("B8000050")
        
        # push receiver object
        if rcvr_name.nil?
          if active_scope.cls.nil?
            raise "Send without receiver"
          else
            append_code hex2bin("8B460450")
          end
        elsif (receiver = @codeset.symbols.find_nearest(active_scope, rcvr_name)).nil?
          raise "Undefined symbol '#{rcvr_name}' in scope '#{active_scope.to_s}'"
        else
          add_variable_ref receiver, code_len + 1
          append_code hex2bin("A1000050")
        end
        
        # call _send_to_object
        add_function_ref SYS_FUNCTIONS[:send_to_obj], code_len + 1
        append_code hex2bin("E80000")
puts "handle_send #{rcvr_name}, #{func_name}, [#{func_args.map{|x|x.text}.join(", ")}]"
      end
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
              elsif SYS_FUNCTIONS.key?(first_node.text.to_sym)
                handle_function_call node
              else
                if (function = @codeset.symbols.find_nearest(current_scope, first_node.text)).nil?
                  raise "Call to undefined function '#{first_node.text}' from scope '#{current_scope.to_s}'"
                elsif !function.is_a?(Function)
                  raise "Call to non-function '#{first_node.text}'"
                else
                  handle_function_call node
                end
              end
            #else
            #  raise "Unexpected node type #{first_node.type.inspect} in #{first_node.inspect}"
            else
              handle_expression node
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
            raise "This branch is not expected to be executed (1)"
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
                cls_object = register_class(cls_name, cls_parent)
                enter_scope Scope.new(cls_name)
                detect_names cls_body
                leave_scope
              end
            end
          elsif first_node.type == :assign
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
          end
        else
          raise "This branch is not expected to be executed (2). node: #{node.inspect}"
        end
      end
    end
    
    public
    def generate_code(nodes)
      @scope_stack = []
      @scope_stack = []
      @codeset = CodeSet.new
      detect_names nodes
      define_system_variables
      handle_any nodes
      @codeset
    end
  end
end
