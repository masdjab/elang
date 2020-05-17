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
        append_hex "B8" + Converter.int2hex(value, :word, :be)
      end
      def load_int(value)
        append_hex "B8" + Converter.int2hex(intobj(value), :word, :be)
      end
      def load_str(text)
        active_scope = current_scope
        
        if (symbol = @symbols.find_string(text)).nil?
          symbol = register_constant(active_scope, Elang::Constant.generate_name, text)
        end
        
        hex_code = 
          [
            "B80000",       # mov eax, string constant
            "50",           # push eax
            "E80000",       # call load_str
          ]
        
        add_constant_ref symbol, code_len + 1
        add_function_ref get_sys_function("_load_str"), code_len + 5
        
        append_hex hex_code.join
      end
      def get_global_variable(symbol)
        # mov var, ax
        add_variable_ref symbol, code_len + 1
        append_hex "A10000"
      end
      def set_global_variable(symbol)
        # mov var, ax
        add_variable_ref symbol, code_len + 2
        add_function_ref get_sys_function("_unassign_object"), code_len + 6
        add_variable_ref symbol, code_len + 10
        append_hex "50A1000050E8000058A30000"
      end
      def get_local_variable(symbol)
        # mov ax, [bp + n]
        add_variable_ref symbol, code_len + 2
        append_hex "8B4600"
      end
      def set_local_variable(symbol)
        # mov [bp + n], ax
        add_variable_ref symbol, code_len + 3
        add_function_ref get_sys_function("_unassign_object"), code_len + 6
        add_variable_ref symbol, code_len + 11
        append_hex "508B460050E8000058894600"
      end
      def get_instance_variable(symbol)
        add_variable_ref symbol, code_len + 1
        add_function_ref get_sys_function("_get_obj_var"), code_len + 9
        append_hex "B80000508B460450E80000"
      end
      def set_instance_variable(symbol)
        add_variable_ref symbol, code_len + 2
        add_function_ref get_sys_function("_set_obj_var"), code_len + 10
        append_hex "50B80000508B460450E80000"
      end
      def get_parameter_by_index(index)
        append_hex "8B46" + Converter.int2hex((index + 2) * 2, :byte, :be)
      end
      def get_parameter_by_symbol(symbol)
        # mov ax, [bp + n]
        add_variable_ref symbol, code_len + 2
        append_hex "8B4600"
      end
      def get_class(symbol)
        # #(todo)#fix binary command
        append_hex "A40000"
      end
      def set_class(symbol)
        ## #(todo)#fix binary command
        append_hex "A70000"
      end
      def get_method_id(func_name)
        add_function_id_ref func_name, code_len + 1
        append_hex "B80000"
      end
      def new_jump_source(condition = nil)
        if condition.nil?
          append_hex "E90000"
          code_len
        elsif condition == :nz
          append_hex "0F850000"
          code_len
        elsif condition == :zr
          append_hex "0F840000"
          code_len
        else
          nil
        end
      end
      def set_jump_target(offset)
        if offset
          @codeset[@current_section].data[offset - 2, 2] = Converter.int2bin(code_len - offset, :word)
        end
      end
      def new_jump_target
        code_len
      end
      def set_jump_source(target, condition = nil)
        if condition.nil?
          append_hex "E9" + Converter.int2bin(target - (code_len + 5), :dword)
        elsif condition == :nz
          append_hex "0F85" + Converter.int2bin(target - (code_len + 6), :dword)
        elsif condition == :zr
          append_hex "0F84" + Converter.int2bin(target - (code_len + 6), :dword)
        end
      end
      def push_argument
        append_hex "50"
      end
      def call_function(symbol)
        add_function_ref symbol, code_len + 1
        append_hex "E80000"
      end
      def call_sys_function(func_name)
        # todo: merge this to call function
        add_function_ref get_sys_function(func_name), code_len + 1
        append_hex "E80000"
      end
      def create_object(cls)
        iv = @symbols.get_instance_variables(cls)
        sz = Converter.int2hex(iv.count, :word, :be)
        ci = Converter.int2hex(cls.clsid, :word, :be)
        hc = "B8#{sz}50B8#{ci}50E80000"
        
        add_function_ref get_sys_function("_alloc_object"), code_len + 9
        append_hex hc
      end
      def define_function(name, params_count)
        old_scope = current_scope
        enter_scope new_scope = Scope.new(current_scope.cls, name)
        function = @symbols.find_exact(old_scope, name)
        function.offset = code_len
        variables = @symbols.items.select{|x|(x.scope.to_s == new_scope.to_s) && x.is_a?(Variable)}
        var_count = variables.count
        
        if old_scope.cls.nil?
          # push bp; mov bp, sp
          append_hex "5589E5"
        end
        
        if var_count > 0
          # sub sp, nn
          append_hex "81EC" + Elang::Converter.int2hex(var_count * 2, :word, :be)
          
          variables.each do |v|
            # xor ax, ax; mov [v], ax
            add_variable_ref v, code_len + 4
            append_hex "31C0894600"
          end
        end
        
        yield
        
        if var_count > 0
          append_hex "50"
          variables.each do |v|
            # mov ax, [v]; push v; call _unassign_object
            add_variable_ref v, code_len + 2
            add_function_ref get_sys_function("_unassign_object"), code_len + 5
            append_hex "8B460050E80000"
          end
          append_hex "58"
          
          # add sp, nn
          append_hex "81C4" + Elang::Converter.int2hex(var_count * 2, :word, :be)
        end
        
        if old_scope.cls.nil?
          # pop bp
          append_hex "5D"
          
          # ret [n]
          hex_code = (params_count > 0 ? "C2#{Elang::Converter.int2hex(params_count * 2, :word, :be).upcase}" : "C3")
          append_hex hex_code
        else
          # ret
          append_hex "C3"
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
        append_hex "E80000"
        
        # push dx; mov dx, ax
        append_hex "5289C2"
      end
      def array_append_item
        add_function_ref get_sys_function("_array_append"), code_len + 3
        append_hex "5052E80000"
      end
      def end_array
        # pop dx
        append_hex "5A"
      end
      def jump(target)
        jmp_to = Converter.int2hex(target - (code_len + 3), :word, :be)
        append_hex "E9#{jmp_to}"
      end
      def enter_breakable_block
        @break_stack << []
      end
      def leave_breakable_block
        @break_stack.pop
      end
      def break_block
        append_break
        append_hex "E90000"
      end
      def resolve_breaks
        break_requests.each do |b|
          jmp_distance = code_len - (b + 3)
          @codeset[@current_section].data[b + 1, 2] = Converter.int2bin(jmp_distance, :word)
        end
      end
    end
  end
end
