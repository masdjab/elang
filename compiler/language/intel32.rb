module Elang
  module Language
    class Intel32 < IntelBase
      private
      def intobj(value)
        (value << 1) | 1
      end
      def make_int(value)
        (value << 1) | (value < 0 ? 0x80000000 : 0) | 1
      end
      
      public
      def load_immediate(value)
        append_code hex2bin("B8" + Converter.int2hex(value, :dword, :be))
      end
      def load_int(value)
        append_code hex2bin("B8" + Converter.int2hex(intobj(value), :dword, :be))
      end
      def load_str(text)
        active_scope = current_scope
        
        if (symbol = @symbols.find_string(text)).nil?
          symbol = Elang::Constant.new(active_scope, Elang::Constant.generate_name, text)
          @symbols.add symbol
        end
        
        hex_code = 
          [
            "B800000000",       # mov eax, string constant
            "50",               # push eax
            "E800000000",       # call load_str
          ]
        
        add_constant_ref symbol, code_len + 1
        add_function_ref get_sys_function("_load_str"), code_len + 7
        
        append_code hex2bin(hex_code.join)
      end
      def get_global_variable(symbol)
        # mov var, ax
        add_variable_ref symbol, code_len + 1
        append_code hex2bin("A100000000")
      end
      def set_global_variable(symbol)
        # mov var, ax
        add_variable_ref symbol, code_len + 2
        add_function_ref get_sys_function("_unassign_object"), code_len + 8
        add_variable_ref symbol, code_len + 14
        append_code hex2bin("50A10000000050E80000000058A300000000")
      end
      def get_local_variable(symbol)
        # mov ax, [bp + n]
        add_variable_ref symbol, code_len + 2
        append_code hex2bin("8B4500")
      end
      def set_local_variable(symbol)
        # mov [bp + n], ax
        add_variable_ref symbol, code_len + 3
        add_function_ref get_sys_function("_unassign_object"), code_len + 6
        add_variable_ref symbol, code_len + 13
        append_code hex2bin("508B450050E80000000058894500")
      end
      def get_instance_variable(symbol)
        add_variable_ref symbol, code_len + 1
        add_function_ref get_sys_function("_get_obj_var"), code_len + 11
        append_code hex2bin("B800000000508B450450E800000000")
      end
      def set_instance_variable(symbol)
        add_variable_ref symbol, code_len + 2
        add_function_ref get_sys_function("_set_obj_var"), code_len + 12
        append_code hex2bin("50B800000000508B450450E800000000")
      end
      def get_parameter_by_index(index)
        append_code hex2bin("8B45" + Converter.int2hex((index + 2) * 4, :byte, :be))
      end
      def get_parameter_by_symbol(symbol)
        # mov ax, [bp + n]
        add_variable_ref symbol, code_len + 2
        append_code hex2bin("8B4500")
      end
      def get_class(symbol)
        # #(todo)#fix binary command
        append_code hex2bin("A400000000")
      end
      def set_class(symbol)
        ## #(todo)#fix binary command
        append_code hex2bin("A700000000")
      end
      def get_method_id(func_name)
        function_id = FunctionId.new(current_scope, func_name)
        add_function_id_ref function_id, code_len + 1
        append_code hex2bin("B800000000")
      end
      def new_jump_source(condition = nil)
        if condition.nil?
          append_code hex2bin("E900000000")
          code_len
        elsif condition == :nz
          append_code hex2bin("0F8500000000")
          code_len
        elsif condition == :zr
          append_code hex2bin("0F8400000000")
          code_len
        else
          nil
        end
      end
      def set_jump_target(offset)
        if offset
          @codeset.code[@codeset.branch][offset - 4, 4] = Converter.int2bin(code_len - offset, :dword, :be)
        end
      end
      def new_jump_target
        code_len
      end
      def set_jump_source(target, condition = nil)
        if condition.nil?
          append_code hex2bin("E9" + Converter.int2bin(target - (code_len + 5), :dword, :be))
        elsif condition == :nz
          append_code hex2bin("0F85" + Converter.int2bin(target - (code_len + 6), :dword, :be))
        elsif condition == :zr
          append_code hex2bin("0F84" + Converter.int2bin(target - (code_len + 6), :dword, :be))
        end
      end
      def push_argument
        append_code hex2bin("50")
      end
      def call_function(symbol)
        add_function_ref symbol, code_len + 1
        append_code hex2bin("E800000000")
      end
      def call_sys_function(func_name)
        # todo: merge this to call function
        add_function_ref SystemFunction.new(func_name), code_len + 1
        append_code hex2bin("E800000000")
      end
      def create_object(cls)
        iv = @symbols.get_instance_variables(cls)
        sz = Converter.int2hex(iv.count, :dword, :be)
        ci = Converter.int2hex(cls.clsid, :dword, :be)
        hc = "B8#{sz}50B8#{ci}50E800000000"
        
        add_function_ref get_sys_function("_alloc_object"), code_len + 13
        append_code hex2bin(hc)
      end
      def define_function(name, params_count)
        old_scope = current_scope
        enter_scope new_scope = Scope.new(current_scope.cls, name)
        variables = @symbols.items.select{|x|(x.scope.to_s == new_scope.to_s) && x.is_a?(Variable)}
        var_count = variables.count
        
        if old_scope.cls.nil?
          # push bp; mov bp, sp
          append_code hex2bin("55" + "89E5")
        end
        
        if var_count > 0
          # sub sp, nn
          append_code hex2bin("83EC" + Elang::Converter.int2hex(var_count * 4, :dword, :be))
          
          variables.each do |v|
            # xor ax, ax; mov [v], ax
            add_variable_ref v, code_len + 4
            append_code hex2bin("31C0894500")
          end
        end
        
        yield
        
        if var_count > 0
          append_code hex2bin("50")
          variables.each do |v|
            # mov ax, [v]; push v; call _unassign_object
            add_variable_ref v, code_len + 2
            add_function_ref get_sys_function("_unassign_object"), code_len + 5
            append_code hex2bin("8B450050E800000000")
          end
          append_code hex2bin("58")
          
          # add sp, nn
          append_code hex2bin("83C4" + Elang::Converter.int2hex(var_count * 4, :dword, :be))
        end
        
        if old_scope.cls.nil?
          # pop bp
          append_code hex2bin("5D")
          
          # ret [n]
          hex_code = (params_count > 0 ? "C2#{Elang::Converter.int2hex(params_count * 4, :word, :be).upcase}" : "C3")
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
        append_code hex2bin("E800000000")
        
        # push dx; mov dx, ax
        append_code hex2bin("5289C2")
      end
      def array_append_item
        add_function_ref get_sys_function("_array_append"), code_len + 3
        append_code hex2bin("5052E800000000")
      end
      def end_array
        # pop dx
        append_code hex2bin("5A")
      end
      def jump(target)
        jmp_to = Converter.int2hex(target - (code_len + 5), :dword, :be)
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
        append_code hex2bin("E900000000")
      end
      def resolve_breaks
        break_requests.each do |b|
          jmp_distance = code_len - (b + 5)
          @codeset.code[@codeset.branch][b + 1, 4] = Converter.int2bin(jmp_distance, :dword)
        end
      end
    end
  end
end
