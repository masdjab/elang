module Elang
  class MethodDispatcher16
    attr_accessor :classes, :code_origin, :dispatcher_offset
    
    private
    def initialize
      @classes = nil
      @code_origin = 0
      @dispatcher_offset = 0
    end
    def asm(code = "", desc = "")
      Assembly::Instruction.new(code, desc)
    end
    
    public
    def setup(symbols, symbol_refs, binary_code)
      @codepad = Elang::CodePad.new(symbols, symbol_refs, binary_code)
    end
    def build_obj_method_dispatcher(subs_offset, subs_length)
      offset_method_selector = {}
      
      dispatcher_offset = subs_offset + subs_length
      
      offset_handle_invalid_class_id = @codepad.code_len
      @codepad.append_hex "B80000"            # mov ax, 0
      @codepad.append_hex "C3"                # ret
      
      offset_handle_method_not_found = @codepad.code_len
      @codepad.append_hex "B80000"            # mov ax, 0
      @codepad.append_hex "C3"                # ret
      
      @classes.each do |key, cls|
        offset_method_selector[key.downcase] = @codepad.code_len
        @codepad.append_hex "8B4606"          # mov ax, [bp + 6]
        
        offset_first_method = @codepad.code_len
        cls[:i_funs].each do |f|
          func_address = Converter.int2hex(@code_origin + subs_offset + f[:offset], :word, :be).upcase
          @codepad.append_hex "3D" + Converter.int2hex(f[:id], :word, :be).upcase + "7504"      # cmp ax, #{f[:id]}; jnz + 2
          @codepad.append_hex "B8#{func_address}C3"                                             # mov ax, #{key.downcase}_obj_#{f[:name]}; ret
        end
        
        if cls[:parent]
          jump_distance = offset_first_method - (@codepad.code_len + 3)
          jump_target = Converter.int2hex(jump_distance, :word, :be).upcase
          @codepad.append_hex "E9#{jump_target}"    # jmp offset_first_method
        else
          code_address = @code_origin + dispatcher_offset + offset_handle_method_not_found
          ax_value = Converter.int2hex(code_address, :word, :be).upcase
          @codepad.append_hex "B8#{ax_value}C3"     # mov ax, offset_handle_method_not_found; ret
        end
      end
      
      
      offset_find_obj_method = @codepad.code_len
      label_find_obj_method = @codepad.register_label(Scope.new, nil, "disp")
      @codepad.append_hex "8B4604"                  # mov ax, [bp + 4]
      
      # add integer class
      if @classes.key?("Integer")
        @codepad.append_hex "A90100"                # test ax, 1
        jump_distance = offset_method_selector["integer"] - (@codepad.code_len + 4)
        jump_target = Converter.int2hex(jump_distance, :word, :be).upcase
        @codepad.append_hex "0F85#{jump_target}"    # jnz method_selector_integer
      end
      
      # add nil class
      if @classes.key?("NilClass")
        @codepad.append_hex "3D" + Converter.int2hex(Class::ROOT_CLASS_IDS["NilClass"], :word, :be)   # cmp ax, nil_class_id
        jump_distance = offset_method_selector["nilclass"] - (@codepad.code_len + 4)
        jump_target = Converter.int2hex(jump_distance, :word, :be).upcase
        @codepad.append_hex "0F84#{jump_target}"    # jz method_selector_nilclass
      end
      
      # add false class
      if @classes.key?("FalseClass")
        @codepad.append_hex "3D" + Converter.int2hex(Class::ROOT_CLASS_IDS["FalseClass"], :word, :be) # cmp ax, false_class_id
        jump_distance = offset_method_selector["falseclass"] - (@codepad.code_len + 4)
        jump_target = Converter.int2hex(jump_distance, :word, :be).upcase
        @codepad.append_hex "0F84#{jump_target}"    # jz method_selector_falseclass
      end
      
      # add true class
      if @classes.key?("TrueClass")
        @codepad.append_hex "3D" + Converter.int2hex(Class::ROOT_CLASS_IDS["TrueClass"], :word, :be)    # cmp ax, true_class_id
        jump_distance = offset_method_selector["trueclass"] - (@codepad.code_len + 4)
        jump_target = Converter.int2hex(jump_distance, :word, :be).upcase
        @codepad.append_hex "0F84#{jump_target}"    # jz method_selector_trueclass
      end
      
      @codepad.append_hex "56"          # push si
      @codepad.append_hex "8B7604"      # mov si, [bp + 4]
      @codepad.append_hex "8B04"        # mov ax, [si]
      @codepad.append_hex "5E"          # pop si
      
      # add non-built-in classes
      @classes.each do |key, cls|
        if !["Integer", "NilClass", "TrueClass", "FalseClass"].include?(key)
          if clsid = cls[:clsid]
            @codepad.append_hex "3D" + Converter.int2hex(cls[:clsid], :word, :be).upcase    # cmp ax, #{cls[:clsid]}
            jump_distance = offset_method_selector[key.downcase] - (@codepad.code_len + 4)
            jump_target = Converter.int2hex(jump_distance, :word, :be).upcase
            @codepad.append_hex "0F84#{jump_target}"      # jz offset_method_selector[key.downcase]
          end
        end
      end
      
      func_address = @code_origin + dispatcher_offset + offset_handle_invalid_class_id
      ax_value = Converter.int2hex(func_address, :word, :be).upcase
      @codepad.append_hex "B8#{ax_value}C3"     # mov ax, offset_handle_invalid_class_id; ret
      
      offset_return_to_caller = @codepad.code_len
      @codepad.append_hex "50"                  # push ax
      @codepad.append_hex "56"                  # push si
      @codepad.append_hex "89EE"                # mov si, bp
      @codepad.append_hex "8B4608"              # mov ax, [bp + 8]
      @codepad.append_hex "83C004"              # add ax, 4
      @codepad.append_hex "D1E0"                # shl ax, 1
      @codepad.append_hex "01C6"                # add si, ax
      @codepad.append_hex "8B4602"              # mov ax, [bp + 2]
      @codepad.append_hex "87EE"                # xchg bp, si
      @codepad.append_hex "894600"              # mov [bp], ax
      @codepad.append_hex "87EE"                # xchg bp, si
      @codepad.append_hex "897602"              # mov [bp + 2], si
      @codepad.append_hex "5E"                  # pop si
      @codepad.append_hex "58"                  # pop ax
      @codepad.append_hex "5D"                  # pop bp
      @codepad.append_hex "5C"                  # pop sp
      @codepad.append_hex "C3"                  # ret
      
      offset_dispatch_obj_method = @codepad.code_len
      @codepad.append_hex "55"                  # push bp
      @codepad.append_hex "89E5"                # mov bp, sp
      code_address = @code_origin + dispatcher_offset + offset_return_to_caller
      ax_value = Converter.int2hex(code_address, :word, :be).upcase
      @codepad.append_hex "B8#{ax_value}"       # mov ax, offset_return_to_caller
      @codepad.append_hex "50"                  # push ax
      
      #call_distance = offset_find_obj_method - (@codepad.code_len + 3)
      #call_target = Converter.int2hex(call_distance, :word, :be).upcase
      #@codepad.append_hex "E8#{call_target}"    # call offset_find_obj_method
      #@codepad.append_hex "50"                  # push ax
      #@codepad.append_hex "C3"                  # ret
      
      #call_distance = offset_find_obj_method - (@codepad.code_len + 6)
      #call_target = Converter.int2hex(call_distance, :word, :be).upcase
      #@codepad.append_hex "B87788"
      #@codepad.append_hex "E8#{call_target}"    # call offset_find_obj_method
      #@codepad.append_hex "50"                  # push ax
      #@codepad.append_hex "C3"                  # ret
      
      @codepad.add_near_code_ref label_find_obj_method, @codepad.code_len + 4, "disp"
      @codepad.append_hex "B87788"
      @codepad.append_hex "E80000"              # call offset_find_obj_method
      @codepad.append_hex "50"                  # push ax
      @codepad.append_hex "C3"                  # ret
      
      @dispatcher_offset = dispatcher_offset + offset_dispatch_obj_method
      
      @codepad.binary_code.to_s
    end
  end
end
