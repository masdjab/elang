module Elang
  class MethodDispatcher32
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
    def build_obj_method_dispatcher(subs_offset, subs_length)
      code_offset = {}
      dispatcher_offset = subs_offset + subs_length
      asmcode = Assembly::CodeBuilder.new
      
      code_label = "handle_invalid_class_id"
      code_offset[code_label] = asmcode.code.length
      asmcode << asm("", "#{code_label}:")
      asmcode << asm("B800000000", "  mov ax, 0")
      asmcode << asm("C3", "  ret")
      
      code_label = "handle_method_not_found"
      code_offset[code_label] = asmcode.code.length
      asmcode << asm("", "#{code_label}:")
      asmcode << asm("B800000000", "  mov ax, 0")
      asmcode << asm("C3", "  ret")
      
      @classes.each do |key, cls|
        code_label = "method_selector_#{key.downcase}"
        code_offset[code_label] = asmcode.code.length
        asmcode << asm("", "#{code_label}:")
        asmcode << asm("8B450C", "  mov ax, [bp + 6]")
        
        code_label = "first_method_#{key.downcase}"
        code_offset[code_label] = asmcode.code.length
        asmcode << asm("", "#{code_label}:")
        
        cls[:i_funs].each do |f|
          func_address = Converter.int2hex(@code_origin + subs_offset + f[:offset], :dword, :be).upcase
          asmcode << asm("3D" + Converter.int2hex(f[:id], :dword, :be).upcase + "7506", "  cmp ax, #{f[:id]}; jnz + 2")
          asmcode << asm("B8#{func_address}C3", "  mov ax, #{key.downcase}_obj_#{f[:name]}; ret")
        end
        
        if cls[:parent]
          code_label = "first_method_#{cls[:parent].downcase}"
          jump_distance = code_offset[code_label] - (asmcode.code.length + 5)
          jump_target = Converter.int2hex(jump_distance, :dword, :be).upcase
          asmcode << asm("E9#{jump_target}", "  jmp #{code_label}")
        else
          code_label = "handle_method_not_found"
          code_address = @code_origin + dispatcher_offset + code_offset[code_label]
          ax_value = Converter.int2hex(code_address, :dword, :be).upcase
          asmcode << asm("B8#{ax_value}C3", "  mov ax, #{code_label}; ret")
        end
      end
      
      
      asmcode << asm()
      code_label = "find_obj_method"
      code_offset[code_label] = asmcode.code.length
      asmcode << asm("", "#{code_label}:")
      
      asmcode << asm("8B4508", "  mov ax, [bp + 8]")
      
      # add integer class
      if @classes.key?("Integer")
        asmcode << asm("A901000000", "  test ax, 1")
        jump_distance = code_offset["method_selector_integer"] - (asmcode.code.length + 6)
        jump_target = Converter.int2hex(jump_distance, :dword, :be).upcase
        asmcode << asm("0F85#{jump_target}", "  jnz method_selector_integer")
      end
      
      # add nil class
      if @classes.key?("NilClass")
        asmcode << asm("3D" + Converter.int2hex(Class::ROOT_CLASS_IDS["NilClass"], :dword, :be), "  cmp ax, nil_class_id")
        jump_distance = code_offset["method_selector_nilclass"] - (asmcode.code.length + 6)
        jump_target = Converter.int2hex(jump_distance, :dword, :be).upcase
        asmcode << asm("0F84#{jump_target}", "  jz method_selector_nilclass")
      end
      
      # add false class
      if @classes.key?("FalseClass")
        asmcode << asm("3D" + Converter.int2hex(Class::ROOT_CLASS_IDS["FalseClass"], :dword, :be), "  cmp ax, false_class_id")
        jump_distance = code_offset["method_selector_falseclass"] - (asmcode.code.length + 6)
        jump_target = Converter.int2hex(jump_distance, :dword, :be).upcase
        asmcode << asm("0F84#{jump_target}", "  jz method_selector_falseclass")
      end
      
      # add true class
      if @classes.key?("TrueClass")
        asmcode << asm("3D" + Converter.int2hex(Class::ROOT_CLASS_IDS["TrueClass"], :dword, :be), "  cmp ax, true_class_id")
        jump_distance = code_offset["method_selector_trueclass"] - (asmcode.code.length + 6)
        jump_target = Converter.int2hex(jump_distance, :dword, :be).upcase
        asmcode << asm("0F84#{jump_target}", "  jz method_selector_trueclass")
      end
      
      asmcode << asm("56", "  push si")
      asmcode << asm("8B7508", "  mov si, [bp + 8]")
      asmcode << asm("8B06", "  mov ax, [si]")
      asmcode << asm("5E", "  pop si")
      
      # add non-built-in classes
      @classes.each do |key, cls|
        if !["Integer", "NilClass", "TrueClass", "FalseClass"].include?(key)
          if clsid = cls[:clsid]
            asmcode << asm("3D" + Converter.int2hex(cls[:clsid], :dword, :be).upcase, "  cmp ax, #{cls[:clsid]}")
            code_label = "method_selector_#{key.downcase}"
            jump_distance = code_offset[code_label] - (asmcode.code.length + 6)
            jump_target = Converter.int2hex(jump_distance, :dword, :be).upcase
            asmcode << asm("0F84#{jump_target}", "  jz #{code_label}")
          end
        end
      end
      
      code_label = "handle_invalid_class_id"
      func_address = @code_origin + dispatcher_offset + code_offset[code_label]
      ax_value = Converter.int2hex(func_address, :dword, :be).upcase
      asmcode << asm("B8#{ax_value}C3", "  mov ax, #{code_label}; ret")
      asmcode << asm()
      
      code_label = "_return_to_caller"
      code_offset[code_label] = asmcode.code.length
      asmcode << asm("",        "#{code_label}:")
      asmcode << asm("50",      "  push ax")
      asmcode << asm("56",      "  push si")
      asmcode << asm("89EE",    "  mov si, bp")
      asmcode << asm("8B4510",  "  mov ax, [bp + 16]")
      asmcode << asm("83C004",  "  add ax, 4")
      asmcode << asm("D1E0",    "  shl ax, 1")
      asmcode << asm("01C6",    "  add si, ax")
      asmcode << asm("8B4504",  "  mov ax, [bp + 4]")
      asmcode << asm("87EE",    "  xchg bp, si")
      asmcode << asm("894500",  "  mov [bp], ax")
      asmcode << asm("87EE",    "  xchg bp, si")
      asmcode << asm("897504",  "  mov [bp + 4], si")
      asmcode << asm("5E",      "  pop si")
      asmcode << asm("58",      "  pop ax")
      asmcode << asm("5D",      "  pop bp")
      asmcode << asm("5C",      "  pop sp")
      asmcode << asm("C3",      "  ret")
      
      asmcode << asm()
      code_label = "dispatch_obj_method"
      code_offset[code_label] = asmcode.code.length
      asmcode << asm("",      "#{code_label}:")
      asmcode << asm("55",    "  push bp")
      asmcode << asm("89E5",  "  mov bp, sp")
      code_label = "_return_to_caller"
      code_address = @code_origin + dispatcher_offset + code_offset[code_label]
      ax_value = Converter.int2hex(code_address, :dword, :be).upcase
      asmcode << asm("B8#{ax_value}", "  mov ax, #{code_label}")
      asmcode << asm("50",    "  push ax")
      asmcode << asm()
      
      code_label = "find_obj_method"
      call_distance = code_offset[code_label] - (asmcode.code.length + 5)
      call_target = Converter.int2hex(call_distance, :dword, :be).upcase
      asmcode << asm("E8#{call_target}", "  call #{code_label}")
      asmcode << asm("50", "  push ax")
      asmcode << asm("C3", "  ret")
      asmcode << asm()
      
      @dispatcher_offset = dispatcher_offset + code_offset["dispatch_obj_method"]
      
      asmcode
    end
  end
end
