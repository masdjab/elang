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
      [
        SystemFunction.new("_int_pack"), 
        SystemFunction.new("_int_unpack"), 
        SystemFunction.new("_int_add"), 
        SystemFunction.new("_int_subtract"), 
        SystemFunction.new("_int_multiply"), 
        SystemFunction.new("_int_divide"), 
        SystemFunction.new("_int_and"), 
        SystemFunction.new("_int_or"), 
        SystemFunction.new("_is_equal"), 
        SystemFunction.new("_is_not_equal"), 
        SystemFunction.new("_is_true"), 
        SystemFunction.new("_get_obj_var"), 
        SystemFunction.new("_set_obj_var"), 
        SystemFunction.new("_send_to_object"), 
        SystemFunction.new("_mem_block_init"), 
        SystemFunction.new("_mem_alloc"), 
        SystemFunction.new("_mem_dealloc"), 
        SystemFunction.new("_mem_get_data_offset"), 
        SystemFunction.new("_alloc_object"), 
        SystemFunction.new("_load_str"), 
        SystemFunction.new("_int_to_h8"), 
        SystemFunction.new("_int_to_h16"), 
        SystemFunction.new("_int_to_s"), 
        SystemFunction.new("_str_length"), 
        SystemFunction.new("_str_lcase"), 
        SystemFunction.new("_str_ucase"), 
        SystemFunction.new("_str_concat"), 
        SystemFunction.new("_str_append"), 
        SystemFunction.new("_str_substr"), 
        SystemFunction.new("_unassign_object"), 
        SystemFunction.new("_collect_garbage"), 
        SystemFunction.new("print"), 
        SystemFunction.new("puts")
      ]
    
    OPERATION_MAP = 
      {
        :plus       => "_int_add", 
        :minus      => "_int_subtract", 
        :star       => "_int_multiply", 
        :slash      => "_int_divide", 
        :and        => "_int_and", 
        :or         => "_int_or", 
        :equal      => "_is_equal", 
        :not_equal  => "_is_not_equal" 
      }
      
    attr_reader :code_lines, :symbols, :symbol_refs
    
    private
    def initialize
      @codeset = CodeSet.new
      @scope_stack = []
    end
    def raize(msg, node = nil)
      raise ParsingError.new(msg, node, @code_lines)
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
    def get_sys_function(name)
      SYS_FUNCTIONS.find{|x|x.name == name}
    end
    def invoke_operation(meth_name)
      add_function_ref get_sys_function(OPERATION_MAP[meth_name]), code_len + 1
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
      active_scope = current_scope
      
      if (symbol = @codeset.symbols.find_string(text)).nil?
        symbol = Elang::Constant.new(active_scope, Elang::Constant.generate_name, text)
        @codeset.symbols.add symbol
      end
      
      hex_code = 
        [
          "BE0000",       # mov si, string constant
          "8B4400",       # mov ax, [si]
          "83C602",       # add si, 2
          "5056",         # push ax; push si
          "E80000",       # call load_str
        ]
      
      add_constant_ref symbol, code_len + 1
      add_function_ref get_sys_function("_load_str"), code_len + 12
      
      append_code hex2bin(hex_code.join)
    end
    def get_variable(node)
      active_scope = current_scope
      
      if node.type == :identifier
        if (name = node.text) == "nil"
          append_code hex2bin("B8" + Utils::Converter.int_to_whex_be(Class::ROOT_CLASS_IDS["NilClass"]))
        elsif name == "true"
          append_code hex2bin("B8" + Utils::Converter.int_to_whex_be(Class::ROOT_CLASS_IDS["TrueClass"]))
        elsif name == "false"
          append_code hex2bin("B8" + Utils::Converter.int_to_whex_be(Class::ROOT_CLASS_IDS["FalseClass"]))
        elsif name == "self"
          if active_scope.cls.nil?
            raize "Symbol 'self' accessed outside class", node
          else
            append_code hex2bin("8B4604")
          end
        elsif (symbol = @codeset.symbols.find_nearest(active_scope, name)).nil?
          raize "Cannot get value from '#{name}' , symbol not defined in scope '#{active_scope.to_s}'", node
        elsif symbol.is_a?(FunctionParameter)
          # mov ax, [bp - n]
          add_variable_ref symbol, code_len + 2
          append_code hex2bin("8B4600")
        elsif symbol.is_a?(InstanceVariable)
          # #(todo)#resolve object id, class id, and instance variable getter address
          if active_scope.cls.nil?
            raize "Instance variable '#{name}' accessed in scope '#{active_scope.to_s}' which is not instance method", node
          elsif (cls = @codeset.symbols.find_exact(Scope.new, active_scope.cls)).nil?
            raize "Class #{active_scope.cls} is not defined", name
          else
            add_variable_ref symbol, code_len + 1
            add_function_ref get_sys_function("_get_obj_var"), code_len + 9
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
          raize "Cannot get value from '#{name}', symbol type '#{symbol.class}' unknown", node
        end
      elsif node.type == :number
        append_code hex2bin("B8" + Utils::Converter.int_to_whex_rev(intobj(node.text.to_i)))
      elsif node.type == :string
        get_string_object node.text
      end
    end
    def set_variable(name)
      if (symbol = @codeset.symbols.find_nearest(active_scope = current_scope, name)).nil?
        raize "Cannot set value to '#{name}' , symbol not defined in scope '#{active_scope.to_s}'"
      elsif symbol.is_a?(FunctionParameter)
        # mov [bp - n], ax
        add_variable_ref symbol, code_len + 3
        add_function_ref get_sys_function("_unassign_object"), code_len + 6
        add_variable_ref symbol, code_len + 11
        append_code hex2bin("508B460050E8000058894600")
      elsif symbol.is_a?(InstanceVariable)
        # #(todo)#fix binary command
        if active_scope.cls.nil?
          raize "Attempted to write to instance variable '#{name}' in scope '#{active_scope.to_s}' which is not instance method"
        elsif (cls = @codeset.symbols.find_exact(Scope.new, active_scope.cls)).nil?
          raize "Class #{active_scope.cls} is not defined"
        else
          add_variable_ref symbol, code_len + 2
          add_function_ref get_sys_function("_set_obj_var"), code_len + 10
          append_code hex2bin("50B80000508B460450E80000")
        end
      elsif symbol.is_a?(ClassVariable)
        ## #(todo)#fix binary command
        append_code hex2bin("A70000")
      elsif symbol.scope.root?
        # mov var, ax
        add_variable_ref symbol, code_len + 2
        add_function_ref get_sys_function("_unassign_object"), code_len + 6
        add_variable_ref symbol, code_len + 10
        append_code hex2bin("50A1000050E8000058A30000")
      elsif symbol.is_a?(Variable)
        # mov [bp + n], ax
        add_variable_ref symbol, code_len + 3
        add_function_ref get_sys_function("_unassign_object"), code_len + 6
        add_variable_ref symbol, code_len + 11
        append_code hex2bin("508B460050E8000058894600")
      else
        raize "Cannot set value to '#{name}', symbol type '#{symbol.class}' unknown"
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
        get_variable node
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
          invoke_operation node[0].type
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
      
      #(todo)#count local_var_count
      enter_scope Scope.new(active_scope.cls, func_name)
      
      function = @codeset.symbols.find_exact(active_scope, func_name)
      function.offset = code_len
      local_variables = @codeset.symbols.items.select{|x|(x.scope.to_s == current_scope.to_s) && x.is_a?(Variable)}
      local_var_count = local_variables.count
      params_count = func_args.count + (rcvr_name ? 2 : 0)
      
      if active_scope.cls.nil?
        # push bp; mov bp, sp
        append_code hex2bin("55" + "89E5")
      end
      
      if local_var_count > 0
        # sub sp, nn
        append_code hex2bin("81EC" + Elang::Utils::Converter.int_to_whex_be(local_var_count * 2))
        
        local_variables.each do |v|
          # xor ax, ax; mov [v], ax
          add_variable_ref v, code_len + 4
          append_code hex2bin("31C0894600")
        end
      end
      
      handle_any func_body
      
      if local_var_count > 0
        local_variables.each do |v|
          # mov ax, [v]; push v; call _unassign_object
          add_variable_ref v, code_len + 2
          add_function_ref get_sys_function("_unassign_object"), code_len + 5
          append_code hex2bin("8B460050E80000")
        end
        
        # add sp, nn
        append_code hex2bin("81C4" + Elang::Utils::Converter.int_to_whex_be(local_var_count * 2))
      end
      
      if active_scope.cls.nil?
        # pop bp
        append_code hex2bin("5D")
        
        # ret [n]
        hex_code = (params_count > 0 ? "C2#{Elang::Utils::Converter.int_to_whex_be(params_count * 2).upcase}" : "C3")
        append_code hex2bin(hex_code)
      else
        # ret
        append_code hex2bin("C3")
      end
      
      leave_scope
    end
    def handle_function_call(node)
      func_name = node[0].text
      
      if get_sys_function(func_name)
        prepare_arguments node[1]
        add_function_ref SystemFunction.new(func_name), code_len + 1
        append_code hex2bin("E80000")
      elsif function = @codeset.symbols.find_function(func_name)
        prepare_arguments node[1]
        add_function_ref function, code_len + 1
        append_code hex2bin("E80000")
      else
        raize "Call to undefined function '#{func_name}'", node[0]
      end
    end
    def handle_send(node)
      # [., receiver, name, args]
      
      active_scope = current_scope
      rcvr_node = node[1]
      func_name = node[2].text
      func_args = node[3] ? node[3] : []
      
      if func_name == "new"
        cls_name = rcvr_node.text
        
        if (cls = @codeset.symbols.items.find{|x|x.is_a?(Class) && (x.name == cls_name)}).nil?
          raize "Class '#{cls_name}' not defined", rcvr_node
        else
          ct = CodesetTool.new(@codeset)
          iv = ct.get_instance_variables(cls)
          sz = Utils::Converter.int_to_whex_rev(iv.count)
          ci = Utils::Converter.int_to_whex_rev(CodesetTool.create_class_id(cls))
          hc = "B8#{sz}50B8#{ci}50E80000"
          
          add_function_ref get_sys_function("_alloc_object"), code_len + 9
          append_code hex2bin(hc)
        end
      else
        if rcvr_node.nil?
          func_sym = @codeset.symbols.find_nearest(active_scope, func_name)
          
          if func_sym.nil? 
            func_sym = get_sys_function(func_name)
          end
          
          if active_scope.cls.nil?
            is_obj_method = false
          elsif func_sym.nil?
            raize "Undefined function '#{func_name}' in scope '#{active_scope.to_s}'", node[2]
          elsif func_sym.is_a?(Function)
            is_obj_method = func_sym.scope.cls == active_scope.cls
          elsif func_sym.is_a?(SystemFunction)
            is_obj_method = false
          else
            raize "Unknown error when handling handle_send for function '#{func_name}' in scope '#{active_scope.to_s}'.", node[2]
          end
        else
          is_obj_method = true
        end
        
        if !is_obj_method
          handle_function_call node[2..3]
        else
          prepare_arguments func_args
          
          # push args count
          append_code hex2bin("B8" + Utils::Converter.int_to_whex_rev(func_args.count) + "50")
          
          # push object method id
          function_id = FunctionId.new(current_scope, func_name)
          add_function_id_ref function_id, code_len + 1
          append_code hex2bin("B8000050")
          
          # push receiver object
          if rcvr_node.nil?
            if active_scope.cls.nil?
              raize "Send without receiver", rcvr_node
            else
              append_code hex2bin("8B460450")
            end
          elsif rcvr_node.is_a?(Array)
            handle_send rcvr_node
            append_code hex2bin("50")
          else
            get_variable rcvr_node
            append_code hex2bin("50")
          end
          
          # call _send_to_object
          add_function_ref get_sys_function("_send_to_object"), code_len + 1
          append_code hex2bin("E80000")
        end
      end
    end
    def handle_class_def(nodes)
      cls_name = nodes[1].text
      cls_prnt = nodes[2] ? nodes[2].text : nil
      
      enter_scope Scope.new(cls_name)
      handle_any nodes[3]
      leave_scope
    end
    def handle_if(nodes)
      cond_node = nodes[1]
      exp1_node = nodes[2]
      exp2_node = nodes.count > 3 ? nodes[3] : nil
      
      handle_expression cond_node
      
      offset1 = code_len
      append_code hex2bin("50E800000F850000")
      
      handle_expression exp1_node
      
      if !exp2_node.nil?
        offset2 = code_len
        append_code hex2bin("E90000")
        jmp_distance = code_len - (offset1 + 8)
        @codeset.code_branch[offset1 + 6, 2] = Utils::Converter.int_to_word(jmp_distance)
        handle_any exp2_node
        jmp_distance = code_len - (offset2 + 3)
        @codeset.code_branch[offset2 + 1, 2] = Utils::Converter.int_to_word(jmp_distance)
      else
        jmp_distance = code_len - (offset1 + 8)
        @codeset.code_branch[offset1 + 6, 2] = Utils::Converter.int_to_word(jmp_distance)
      end
      
      add_function_ref get_sys_function("_is_true"), offset1 + 2
    end
    def handle_any(nodes)
      nodes.each do |node|
        if node.is_a?(Array)
          if !(first_node = node[0]).is_a?(Elang::AstNode)
            raize "Expected identifier, #{first_node} given", node
          elsif first_node.type == :assign
            handle_assignment node
          elsif first_node.type == :dot
            handle_send node
          elsif first_node.type == :identifier
            if first_node.text == "def"
              handle_function_def node
            elsif first_node.text == "class"
              handle_class_def node
            elsif ["if", "elsif"].include?(first_node.text)
              handle_if node
            elsif first_node.text.index("@@")
              register_class_variable first_node.text
              get_variable first_node
            elsif first_node.text.index("@")
              register_instance_variable first_node.text
              get_variable first_node
            elsif ["self"].include?(first_node.text)
              # ignore this
            elsif get_sys_function(first_node.text)
              handle_function_call node
            else
              if (function = @codeset.symbols.find_nearest(current_scope, first_node.text)).nil?
                raize "Call to undefined function '#{first_node.text}' from scope '#{current_scope.to_s}'", first_node
              elsif !function.is_a?(Function)
                raize "Call to non-function '#{first_node.text}'", first_node
              else
                handle_function_call node
              end
            end
          else
            handle_expression node
          end
        else
          handle_expression node
        end
      end
    end
    def detect_names(nodes)
      nodes.each do |node|
        if node.is_a?(Array)
          if (first_node = node[0]).is_a?(Array)
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
                raize "Function cannot be nested", first_node
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
                raize "Class cannot be nested", first_node
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
              raize "Left operand for assignment must be a symbol, #{left_var.inspect} given", left_var
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
          # case examples:
          # @name
        end
      end
    end
    
    public
    def generate_code(nodes, code_lines = [])
      result = nil
      
      begin
        @code_lines = code_lines
        @scope_stack = []
        @scope_stack = []
        @codeset = CodeSet.new
        detect_names nodes
        handle_any nodes
        result = @codeset
      rescue StandardError => e
        Exception.show e
      end
      
      result
    end
  end
end
