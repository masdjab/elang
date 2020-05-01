module Elang
  module Language
    class Intel16 < IntelBase
      private
      def intobj(value)
        (value << 1) | 1
      end
      def make_int(value)
        (value << 1) | (value < 0 ? 0x8000 : 0) | 1
      end
      
      public
      def load_immediate(value)
        append_code hex2bin("B8" + Converter.int2hex(value, :word, :be))
      end
      def load_int(value)
        append_code hex2bin("B8" + Converter.int2hex(intobj(value), :word, :be))
      end
      def load_str(text)
        active_scope = current_scope
        
        if (symbol = @symbols.find_string(text)).nil?
          symbol = Elang::Constant.new(active_scope, Elang::Constant.generate_name, text)
          @symbols.add symbol
        end
        
        hex_code = 
          [
            "B80000",       # mov eax, string constant
            "50",           # push eax
            "E80000",       # call load_str
          ]
        
        add_constant_ref symbol, code_len + 1
        add_function_ref get_sys_function("_load_str"), code_len + 5
        
        append_code hex2bin(hex_code.join)
      end
      def get_global_variable(symbol)
        # mov var, ax
        add_variable_ref symbol, code_len + 1
        append_code hex2bin("A10000")
      end
      def set_global_variable(symbol)
        # mov var, ax
        add_variable_ref symbol, code_len + 2
        add_function_ref get_sys_function("_unassign_object"), code_len + 6
        add_variable_ref symbol, code_len + 10
        append_code hex2bin("50A1000050E8000058A30000")
      end
      def get_local_variable(symbol)
        # mov ax, [bp + n]
        add_variable_ref symbol, code_len + 2
        append_code hex2bin("8B4600")
      end
      def set_local_variable(symbol)
        # mov [bp + n], ax
        add_variable_ref symbol, code_len + 3
        add_function_ref get_sys_function("_unassign_object"), code_len + 6
        add_variable_ref symbol, code_len + 11
        append_code hex2bin("508B460050E8000058894600")
      end
      def get_instance_variable(symbol)
        add_variable_ref symbol, code_len + 1
        add_function_ref get_sys_function("_get_obj_var"), code_len + 9
        append_code hex2bin("B80000508B460450E80000")
      end
      def set_instance_variable(symbol)
        add_variable_ref symbol, code_len + 2
        add_function_ref get_sys_function("_set_obj_var"), code_len + 10
        append_code hex2bin("50B80000508B460450E80000")
      end
      def get_parameter_by_index(index)
        append_code hex2bin("8B46" + Converter.int2hex((index + 2) * 2, :byte, :be))
      end
      def get_parameter_by_symbol(symbol)
        # mov ax, [bp + n]
        add_variable_ref symbol, code_len + 2
        append_code hex2bin("8B4600")
      end
      def get_class(symbol)
        # #(todo)#fix binary command
        append_code hex2bin("A40000")
      end
      def set_class(symbol)
        ## #(todo)#fix binary command
        append_code hex2bin("A70000")
      end
      def get_method_id(func_name)
        function_id = FunctionId.new(current_scope, func_name)
        add_function_id_ref function_id, code_len + 1
        append_code hex2bin("B80000")
      end
      def push_argument
        append_code hex2bin("50")
      end
      def call_function(symbol)
        add_function_ref symbol, code_len + 1
        append_code hex2bin("E80000")
      end
      def call_sys_function(func_name)
        # todo: merge this to call function
        add_function_ref SystemFunction.new(func_name), code_len + 1
        append_code hex2bin("E80000")
      end
      def create_object(cls)
        iv = @symbols.get_instance_variables(cls)
        sz = Converter.int2hex(iv.count, :word, :be)
        ci = Converter.int2hex(cls.clsid, :word, :be)
        hc = "B8#{sz}50B8#{ci}50E80000"
        
        add_function_ref get_sys_function("_alloc_object"), code_len + 9
        append_code hex2bin(hc)
      end
      def define_function(name, params_count)
        enter_scope scope = Scope.new(current_scope.cls, name)
        variables = @symbols.items.select{|x|(x.scope.to_s == scope.to_s) && x.is_a?(Variable)}
        
        if scope.cls.nil?
          # push bp; mov bp, sp
          append_code hex2bin("55" + "89E5")
        end
        
        if (var_count = variables.count) > 0
          # sub sp, nn
          append_code hex2bin("81EC" + Elang::Converter.int2hex(var_count * 2, :word, :be))
          
          variables.each do |v|
            # xor ax, ax; mov [v], ax
            add_variable_ref v, code_len + 4
            append_code hex2bin("31C0894600")
          end
        end
        
        yield
        
        if (var_count = variables.count) > 0
          append_code hex2bin("50")
          variables.each do |v|
            # mov ax, [v]; push v; call _unassign_object
            add_variable_ref v, code_len + 2
            add_function_ref get_sys_function("_unassign_object"), code_len + 5
            append_code hex2bin("8B460050E80000")
          end
          append_code hex2bin("58")
          
          # add sp, nn
          append_code hex2bin("81C4" + Elang::Converter.int2hex(var_count * 2, :word, :be))
        end
        
        if scope.cls.nil?
          # pop bp
          append_code hex2bin("5D")
          
          # ret [n]
          hex_code = (params_count > 0 ? "C2#{Elang::Converter.int2hex(params_count * 2, :word, :be).upcase}" : "C3")
          append_code hex2bin(hex_code)
        else
          # ret
          append_code hex2bin("C3")
        end
        
        leave_scope
      end
      def define_class(name)
        enter_scope Scope.new(name)
        yield
        leave_scope
      end
      def begin_array
        add_function_ref get_sys_function("_create_array"), code_len + 1
        append_code hex2bin("E80000")
        
        # push dx; mov dx, ax
        append_code hex2bin("5289C2")
      end
      def array_append_item
        add_function_ref get_sys_function("_array_append"), code_len + 3
        append_code hex2bin("5052E80000")
      end
      def end_array
        # pop dx
        append_code hex2bin("5A")
      end
      def jump(target)
        jmp_to = Converter.int2hex(target - (code_len + 3), :word, :be)
        append_code hex2bin("E9#{jmp_to}")
      end
      def enter_breakable_block
        @break_stack << []
      end
      def leave_breakable_block
        @break_stack.pop
      end
      def break_block
        append_break
        append_code hex2bin("E90000")
      end
      def resolve_breaks
        break_requests.each do |b|
          jmp_distance = code_len - (b + 3)
          @codeset.code[@codeset.branch][b + 1, 2] = Converter.int2bin(jmp_distance, :word)
        end
      end
    end
  end
end
