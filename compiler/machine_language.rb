module Elang
  class MachineLanguage < BaseLanguage
    def raize(msg, node = nil)
      if node
        raise ParsingError.new(msg, node.row, node.col, @source)
      else
        raise ParsingError.new(msg)
      end
    end
    def code_len
      @codeset.length
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
      @scope_stack.current_scope
    end
    def enter_scope(scope)
      @codeset.enter_subs
      @scope_stack.enter_scope scope
    end
    def leave_scope
      @scope_stack.leave_scope
      @codeset.leave_subs
    end
    def code_type
      !current_scope.to_s.empty? ? :subs : :main
    end
    def add_constant_ref(symbol, location)
      @codeset.add_constant_ref(current_scope, symbol, location, code_type)
    end
    def add_variable_ref(symbol, location)
      @codeset.add_variable_ref(current_scope, symbol, location, code_type)
    end
    def add_function_ref(symbol, location)
      @codeset.add_function_ref(current_scope, symbol, location, code_type)
    end
    def add_function_id_ref(symbol, location)
      @codeset.add_function_id_ref(current_scope, symbol, location, code_type)
    end
    def append_code(code)
      @codeset.append code
    end
=begin
    def get_sys_function(name)
      SYS_FUNCTIONS.find{|x|x.name == name}
    end
    def register_variable(name)
      receiver = Elang::Variable.new(current_scope, name)
      @symbols.add receiver
      receiver
    end
=end
    def register_instance_variable(name)
      @symbols.register_instance_variable(Scope.new(current_scope.cls), name)
    end
=begin
    def register_class(name, parent)
      scope = Scope.new
      clist = @symbols.items.select{|x|x.is_a?(Class)}
      
      if (cls = clist.find{|x|x.name == name}).nil?
        idx = clist.inject(0){|a,b|b.index >= a ? b.index + 1 : a}
        @symbols.add(cls = Class.new(scope, name, parent, idx))
      end
      
      cls
    end
    def register_class_variable(name)
      receiver = ClassVariable.new(current_scope, name)
      @symbols.add receiver
      receiver
    end
    def register_function(scope, rcvr_name, func_name, func_args)
      if (fun = @symbols.items.find{|x|(x.name == func_name) && x.is_a?(Function) && (x.scope.to_s == scope.to_s)}).nil?
        fun = Function.new(scope, rcvr_name, func_name, func_args, 0)
        @symbols.add(fun)
      end
      
      fun
    end
    def handle_any(node)
      if node.is_a?(Array)
        node.each{|x|handle_any(x)}
      elsif node.is_a?(Lex::Send)
        handle_send node
      elsif node.is_a?(Lex::Function)
        handle_function_def node
      elsif node.is_a?(Lex::Class)
        handle_class_def node
      elsif node.is_a?(Lex::IfBlock)
        handle_if node
      elsif node.is_a?(Lex::Node)
        if node.type == :identifier
          if ["false", "true", "nil"].include?(node.text)
            get_value node
          elsif node.text.index("@@")
            register_class_variable node.text
            get_value node
          elsif node.text.index("@")
            register_instance_variable node.text
            get_value node
          elsif ["self"].include?(node.text)
            # ignore this
          elsif get_sys_function(node.text)
            handle_function_call Lex::Send.new(nil, node, [])
          else
            if (smbl = @symbols.find_nearest(current_scope, node.text)).nil?
              raize "Call to undefined function '#{node.text}' from scope '#{current_scope.to_s}'", node
            elsif smbl.is_a?(Function)
              handle_function_call node
            else
              get_value node
            end
          end
        elsif [:string, :number].include?(node.type)
          get_value node
        end
      elsif node.is_a?(Lex::Values)
        node.items.each{|i|handle_any(i)}
      else
        raise "Unexpected node: #{node.inspect}"
      end
    end
=end
    
    public
    def get_number(number)
      # mov ax, imm
      value_hex = Elang::Utils::Converter.int_to_whex_be(make_int(number)).upcase
      append_code hex2bin("B8" + value_hex)
    end
    def get_string_object(text)
      active_scope = current_scope
      
      if (symbol = @symbols.find_string(text)).nil?
        symbol = Elang::Constant.new(active_scope, Elang::Constant.generate_name, text)
        @symbols.add symbol
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
    def get_value(node)
      active_scope = current_scope
      
      if node.type == :identifier
        if (name = node.text) == "nil"
          append_code hex2bin("B8" + Utils::Converter.int_to_whex_be(Class::ROOT_CLASS_IDS["NilClass"]))
        elsif name == "false"
          append_code hex2bin("B8" + Utils::Converter.int_to_whex_be(Class::ROOT_CLASS_IDS["FalseClass"]))
        elsif name == "true"
          append_code hex2bin("B8" + Utils::Converter.int_to_whex_be(Class::ROOT_CLASS_IDS["TrueClass"]))
        elsif name == "self"
          if active_scope.cls.nil?
            raize "Symbol 'self' accessed outside class", node
          else
            append_code hex2bin("8B4604")
          end
        elsif (symbol = @symbols.find_nearest(active_scope, name)).nil?
          raize "Cannot get value from '#{name}' , symbol not defined in scope '#{active_scope.to_s}'", node
        elsif symbol.is_a?(FunctionParameter)
          # mov ax, [bp - n]
          add_variable_ref symbol, code_len + 2
          append_code hex2bin("8B4600")
        elsif symbol.is_a?(InstanceVariable)
          # #(todo)#resolve object id, class id, and instance variable getter address
          if active_scope.cls.nil?
            raize "Instance variable '#{name}' accessed in scope '#{active_scope.to_s}' which is not instance method", node
          elsif (cls = @symbols.find_exact(Scope.new, active_scope.cls)).nil?
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
    def set_value(name)
      if (symbol = @symbols.find_nearest(active_scope = current_scope, name)).nil?
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
        elsif (cls = @symbols.find_exact(Scope.new, active_scope.cls)).nil?
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
        get_value node
      end
    end
    def prepare_arguments(arguments)
      (0...arguments.count).map{|x|x}.reverse.each do |i|
        handle_any arguments[i]
        append_code hex2bin("50")
      end
    end
    def handle_function_call(node)
      name_node = node.cmd
      func_name = name_node.text
      func_args = node.args
      
      if get_sys_function(func_name)
        prepare_arguments func_args
        add_function_ref SystemFunction.new(func_name), code_len + 1
        append_code hex2bin("E80000")
      elsif function = @symbols.find_function(func_name)
        prepare_arguments func_args
        add_function_ref function, code_len + 1
        append_code hex2bin("E80000")
      else
        raize "Call to undefined function '#{func_name}'", name_node
      end
    end
    def handle_send(node)
      # [., receiver, name, args]
      
      active_scope = current_scope
      rcvr_node = node.receiver
      cmnd_node = node.cmd
      args_node = node.args
      
      if cmnd_node.type == :assign
        handle_any args_node
        set_value rcvr_node.text
      else
        if (cmnd_node.type == :identifier) && (cmnd_node.text == "new")
          cls_name = rcvr_node.text
          
          if (cls = @symbols.items.find{|x|x.is_a?(Class) && (x.name == cls_name)}).nil?
            raize "Class '#{cls_name}' not defined", rcvr_node
          else
            iv = @symbols.get_instance_variables(cls)
            sz = Utils::Converter.int_to_whex_rev(iv.count)
            ci = Utils::Converter.int_to_whex_rev(Symbols.create_class_id(cls))
            hc = "B8#{sz}50B8#{ci}50E80000"
            
            add_function_ref get_sys_function("_alloc_object"), code_len + 9
            append_code hex2bin(hc)
          end
        else
          func_name = cmnd_node.text
          func_args = args_node ? args_node : []
          
          if rcvr_node.nil?
            func_sym = @symbols.find_nearest(active_scope, func_name)
            
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
            handle_function_call node
          else
            prepare_arguments func_args
            
            # push args count
            args_count = func_args.count
            append_code hex2bin("B8" + Utils::Converter.int_to_whex_rev(args_count) + "50")
            
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
            else
              handle_any rcvr_node
              append_code hex2bin("50")
            end
            
            # call _send_to_object
            add_function_ref get_sys_function("_send_to_object"), code_len + 1
            append_code hex2bin("E80000")
          end
        end
      end
    end
    def handle_function_def(node)
      active_scope = current_scope
      
      rcvr_name = node.receiver ? node.receiver.text : active_scope.cls
      func_name = node.name.text
      func_args = node.params
      func_body = node.body
      
      #(todo)#count local_var_count
      enter_scope Scope.new(active_scope.cls, func_name)
      
      function = @symbols.find_exact(active_scope, func_name)
      function.offset = code_len
      local_variables = @symbols.items.select{|x|(x.scope.to_s == current_scope.to_s) && x.is_a?(Variable)}
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
        append_code hex2bin("50")
        local_variables.each do |v|
          # mov ax, [v]; push v; call _unassign_object
          add_variable_ref v, code_len + 2
          add_function_ref get_sys_function("_unassign_object"), code_len + 5
          append_code hex2bin("8B460050E80000")
        end
        append_code hex2bin("58")
        
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
    def handle_class_def(node)
      cls_name = node.name.text
      cls_prnt = node.parent ? node.parent.text : nil
      
      enter_scope Scope.new(cls_name)
      handle_any node.body
      leave_scope
    end
    def handle_if(node)
      cond_node = node.condition
      exp1_node = node.body1
      exp2_node = node.body2
      
      handle_any cond_node
      
      offset1 = code_len
      append_code hex2bin("50E800000F850000")
      
      handle_any exp1_node
      
      if !exp2_node.nil?
        offset2 = code_len
        append_code hex2bin("E90000")
        jmp_distance = code_len - (offset1 + 8)
        @codeset.code[@codeset.branch][offset1 + 6, 2] = Utils::Converter.int_to_word(jmp_distance)
        handle_any exp2_node
        jmp_distance = code_len - (offset2 + 3)
        @codeset.code[@codeset.branch][offset2 + 1, 2] = Utils::Converter.int_to_word(jmp_distance)
      else
        jmp_distance = code_len - (offset1 + 8)
        @codeset.code[@codeset.branch][offset1 + 6, 2] = Utils::Converter.int_to_word(jmp_distance)
      end
      
      add_function_ref get_sys_function("_is_true"), offset1 + 2
    end
  end
end
