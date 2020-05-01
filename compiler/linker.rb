require_relative 'code'
require_relative 'kernel'
require_relative 'converter'
require_relative 'assembly/instruction'
require_relative 'assembly/code_builder'

module Elang
  class Linker
    HEAP_SIZE   = 0x8000
    FIRST_BLOCK = 0
    
    private
    def initialize(kernel, language)
      @kernel = kernel
      @language = language
      @code_origin = 0x100
      @classes = {}
      @root_var_count = 0
      @function_names = []
      @dynamic_area = 0
      @dispatcher_offset = 0
      @string_constants = {}
      @variable_offset = 0
    end
    def hex2bin(h)
      Converter.hex2bin(h)
    end
    def asm(code = "", desc = "")
      Assembly::Instruction.new(code, desc)
    end
    def build_root_var_indices(symbols)
      symbols.items.each do |s|
        if s.is_a?(Variable) && s.scope.root?
          @root_var_count += 1
          s.index = @root_var_count
        end
      end
    end
    def build_string_constants(symbols, offset)
      cons = {}
      offs = offset
      
      symbols.items.each do |s|
        if s.is_a?(Constant)
          text = s.value
          text = text.gsub("\\r", "\r")
          text = text.gsub("\\n", "\n")
          text = text.gsub("\\t", "\t")
          text = text.gsub("\\\"", "\"")
          
          lgth = text.length
          cons[s.name] = {text: text, length: lgth, offset: offs}
          offs = offs + lgth + 2
        end
      end
      
      cons
    end
    def build_constant_data(constants)
      cons = ""
      
      constants.each do |k,v|
        lgth = Converter.int2bin(v[:length], :word)
        cons << "#{lgth}#{v[:text]}"
      end
      
      if (cons.length > 0) && ((cons.length % 2) > 0)
        cons << 0.chr
      end
      
      cons
    end
    def build_class_hierarchy(symbols)
      @function_names = symbols.get_function_names
      @classes = symbols.get_classes_hierarchy
    end
    def build_code_initializer(symbol_refs, codeset)
      rv_heap_size = Converter.int2hex(HEAP_SIZE, :word, :be)
      first_block_adr = Converter.int2hex(FIRST_BLOCK, :word, :be)
      dynamic_area_adr = Converter.int2hex(@dynamic_area, :word, :be)
      
      if @root_var_count > 0
        cx = Converter.int2hex(@root_var_count, :word, :be)
        di = Converter.int2hex(@variable_offset, :word, :be)
        
        commands = 
          [
            "B9#{cx}",  # mov cx, xx
            "31C0",     # xor ax, ax
            "BF#{di}",  # mov di, variable_offset
            "FC",       # cld
            "F2",       # repnz
            "AB",       # stosw
          ]
        
        init_vars = commands.join
      else
        init_vars = ""
      end
      
      init_cmnd = 
        [
          "8CC8",                     # mov ax, cs
          "050000",                   # add ax, 0
          "8ED0",                     # mov ss, ax
          "8ED8",                     # mov ds, ax
          "8EC0",                     # mov es, ax
          init_vars, 
          "B8#{rv_heap_size}50",      # push heap_size
          "B8#{dynamic_area_adr}50",  # push dynamic_area
          "E80000",                   # call mem_block_init
          "A3#{first_block_adr}"      # mov [first_block], ax
        ]
      
      root_scope = Scope.new
      symbol_refs << FunctionRef.new(SystemFunction.new("_mem_block_init"), root_scope, 20 + (init_vars.length / 2), :init)
      hex2bin init_cmnd.join
    end
    def build_cls_method_dispatcher
      #(todo)#build class methods dispatcher
    end
    def build_obj_method_dispatcher(subs_offset, subs_length)
      code_offset = {}
      dispatcher_offset = subs_offset + subs_length
      asmcode = Assembly::CodeBuilder.new
      
      code_label = "handle_invalid_class_id"
      code_offset[code_label] = asmcode.code.length
      asmcode << asm("", "#{code_label}:")
      asmcode << asm("B80000", "  mov ax, 0")
      asmcode << asm("C3", "  ret")
      
      code_label = "handle_method_not_found"
      code_offset[code_label] = asmcode.code.length
      asmcode << asm("", "#{code_label}:")
      asmcode << asm("B80000", "  mov ax, 0")
      asmcode << asm("C3", "  ret")
      
      @classes.each do |key, cls|
        code_label = "method_selector_#{key.downcase}"
        code_offset[code_label] = asmcode.code.length
        asmcode << asm("", "#{code_label}:")
        asmcode << asm("8B4606", "  mov ax, [bp + 6]")
        
        code_label = "first_method_#{key.downcase}"
        code_offset[code_label] = asmcode.code.length
        asmcode << asm("", "#{code_label}:")
        
        cls[:i_funs].each do |f|
          func_address = Converter.int2hex(@code_origin + subs_offset + f[:offset], :word, :be).upcase
          asmcode << asm("3D" + Converter.int2hex(f[:id], :word, :be) + "7504", "  cmp ax, #{f[:id]}; jnz + 2")
          asmcode << asm("B8#{func_address}C3", "  mov ax, #{key.downcase}_obj_#{f[:name]}; ret")
        end
        
        if cls[:parent]
          code_label = "first_method_#{cls[:parent].downcase}"
          jump_distance = code_offset[code_label] - (asmcode.code.length + 3)
          jump_target = Converter.int2hex(jump_distance, :word, :be).upcase
          asmcode << asm("E9#{jump_target}", "  jmp #{code_label}")
        else
          code_label = "handle_method_not_found"
          code_address = @code_origin + dispatcher_offset + code_offset[code_label]
          ax_value = Converter.int2hex(code_address, :word, :be).upcase
          asmcode << asm("B8#{ax_value}C3", "  mov ax, #{code_label}; ret")
        end
      end
      
      
      asmcode << asm()
      code_label = "find_obj_method"
      code_offset[code_label] = asmcode.code.length
      asmcode << asm("", "#{code_label}:")
      
      asmcode << asm("8B4604", "  mov ax, [bp + 4]")
      
      # add integer class
      if @classes.key?("Integer")
        asmcode << asm("A90100", "  test ax, 1")
        jump_distance = code_offset["method_selector_integer"] - (asmcode.code.length + 4)
        jump_target = Converter.int2hex(jump_distance, :word, :be).upcase
        asmcode << asm("0F85#{jump_target}", "  jnz method_selector_integer")
      end
      
      # add nil class
      if @classes.key?("NilClass")
        asmcode << asm("3D" + Converter.int2hex(Class::ROOT_CLASS_IDS["NilClass"], :word, :be), "  cmp ax, nil_class_id")
        jump_distance = code_offset["method_selector_nilclass"] - (asmcode.code.length + 4)
        jump_target = Converter.int2hex(jump_distance, :word, :be).upcase
        asmcode << asm("0F84#{jump_target}", "  jz method_selector_nilclass")
      end
      
      # add false class
      if @classes.key?("FalseClass")
        asmcode << asm("3D" + Converter.int2hex(Class::ROOT_CLASS_IDS["FalseClass"], :word, :be), "  cmp ax, false_class_id")
        jump_distance = code_offset["method_selector_falseclass"] - (asmcode.code.length + 4)
        jump_target = Converter.int2hex(jump_distance, :word, :be).upcase
        asmcode << asm("0F84#{jump_target}", "  jz method_selector_falseclass")
      end
      
      # add true class
      if @classes.key?("TrueClass")
        asmcode << asm("3D" + Converter.int2hex(Class::ROOT_CLASS_IDS["TrueClass"], :word, :be), "  cmp ax, true_class_id")
        jump_distance = code_offset["method_selector_trueclass"] - (asmcode.code.length + 4)
        jump_target = Converter.int2hex(jump_distance, :word, :be).upcase
        asmcode << asm("0F84#{jump_target}", "  jz method_selector_trueclass")
      end
      
      asmcode << asm("56", "  push si")
      asmcode << asm("8B7604", "  mov si, [bp + 4]")
      asmcode << asm("8B04", "  mov ax, [si]")
      asmcode << asm("5E", "  pop si")
      
      # add non-built-in classes
      @classes.each do |key, cls|
        if !["Integer", "NilClass", "TrueClass", "FalseClass"].include?(key)
          if clsid = cls[:clsid]
            asmcode << asm("3D" + Converter.int2hex(cls[:clsid], :word, :be).upcase, "  cmp ax, #{cls[:clsid]}")
            code_label = "method_selector_#{key.downcase}"
            jump_distance = code_offset[code_label] - (asmcode.code.length + 4)
            jump_target = Converter.int2hex(jump_distance, :word, :be).upcase
            asmcode << asm("0F84#{jump_target}", "  jz #{code_label}")
          end
        end
      end
      
      code_label = "handle_invalid_class_id"
      func_address = @code_origin + dispatcher_offset + code_offset[code_label]
      ax_value = Converter.int2hex(func_address, :word, :be).upcase
      asmcode << asm("B8#{ax_value}C3", "  mov ax, #{code_label}; ret")
      asmcode << asm()
      
      code_label = "_return_to_caller"
      code_offset[code_label] = asmcode.code.length
      asmcode << asm("",        "#{code_label}:")
      asmcode << asm("50",      "  push ax")
      asmcode << asm("56",      "  push si")
      asmcode << asm("89EE",    "  mov si, bp")
      asmcode << asm("8B4608",  "  mov ax, [bp + 8]")
      asmcode << asm("83C004",  "  add ax, 4")
      asmcode << asm("D1E0",    "  shl ax, 1")
      asmcode << asm("01C6",    "  add si, ax")
      asmcode << asm("8B4602",  "  mov ax, [bp + 2]")
      asmcode << asm("87EE",    "  xchg bp, si")
      asmcode << asm("894600",  "  mov [bp], ax")
      asmcode << asm("87EE",    "  xchg bp, si")
      asmcode << asm("897602",  "  mov [bp + 2], si")
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
      ax_value = Converter.int2hex(code_address, :word, :be).upcase
      asmcode << asm("B8#{ax_value}", "  mov ax, #{code_label}")
      asmcode << asm("50",    "  push ax")
      asmcode << asm()
      
      code_label = "find_obj_method"
      call_distance = code_offset[code_label] - (asmcode.code.length + 3)
      call_target = Converter.int2hex(call_distance, :word, :be).upcase
      asmcode << asm("E8#{call_target}", "  call #{code_label}")
      asmcode << asm("50", "  push ax")
      asmcode << asm("C3", "  ret")
      asmcode << asm()
      
      @dispatcher_offset = dispatcher_offset + code_offset["dispatch_obj_method"]
      
      asmcode
    end
    def resolve_references(type, code, refs, origin)
      if !code.empty?
        refs.each do |ref|
          if ref.code_type == type
            symbol = ref.symbol
            
            if symbol.is_a?(Constant)
              resolve_value = @string_constants[symbol.name][:offset]
              code[ref.location, 2] = Converter.int2bin(resolve_value, :word)
            elsif symbol.is_a?(FunctionParameter)
              arg_offset = symbol.scope.cls ? 3 : 0
              resolve_value = (arg_offset + symbol.index + 2) * 2
              code[ref.location, 1] = Converter.int2bin(resolve_value, :byte)
            elsif symbol.is_a?(Variable)
              if symbol.scope.root?
                resolve_value = @variable_offset + (symbol.index - 1) * 2
                code[ref.location, 2] = Converter.int2bin(resolve_value, :word)
              else
                resolve_value = -symbol.index * 2
                code[ref.location, 1] = Converter.int2bin(resolve_value, :byte)
              end
            elsif symbol.is_a?(InstanceVariable)
              if (clsinfo = @classes[symbol.scope.cls]).nil?
                raise "Cannot find class '#{symbol.scope.cls}' in class info list"
              elsif (index = clsinfo[:i_vars].index(symbol.name)).nil?
                raise "Cannot find instance variable '#{symbol.name}' in '#{symbol.scope.cls}' class info"
              else
                code[ref.location, 2] = Converter.int2bin(index, :word)
              end
            elsif symbol.is_a?(Function)
              resolve_value = symbol.offset - (origin + ref.location + 2)
              code[ref.location, 2] = Converter.int2bin(resolve_value, :word)
            elsif symbol.is_a?(SystemFunction)
              if symbol.name == "_send_to_object"
                resolve_value = @dispatcher_offset - (origin + ref.location + 2)
                code[ref.location, 2] = Converter.int2bin(resolve_value, :word)
              elsif sys_function = @kernel.functions[symbol.name]
                resolve_value = sys_function[:offset] - (origin + ref.location + 2)
                code[ref.location, 2] = Converter.int2bin(resolve_value, :word)
              else
                raise "Undefined system function '#{symbol.name.inspect}'"
              end
            elsif symbol.is_a?(FunctionId)
              if (resolve_value = @function_names.index(symbol.name)).nil?
                raise "Unknown method '#{symbol.name}'"
              else
                code[ref.location, 2] = Converter.int2bin(resolve_value, :word)
              end
            elsif symbol.is_a?(Class)
#puts "Resolving class '#{symbol.name}', index: #{symbol.index}"
            else
              raise "Cannot resolve reference to symbol of type '#{symbol.class}' => #{ref.inspect}"
            end
          end
        end
      end
    end
    
    public
    def link(symbols, symbol_refs, codeset)
      head_code = Code.align(hex2bin("B8000050C3"), 16)
      libs_code = @kernel.code
      subs_code = Code.align(codeset.render(:subs), 16)
      main_code = codeset.render(:main) + Elang::Converter.hex2bin("CD20")
      head_size = head_code.length
      libs_size = libs_code.length
      subs_size = subs_code.length
      main_size = main_code.length
      
      build_root_var_indices(symbols)
      reserved_image = 0.chr * (2 * Variable::RESERVED_VARIABLE_COUNT)
      @string_constants = build_string_constants(symbols, reserved_image.length)
      constant_image = build_constant_data(@string_constants)
      cons_data = !constant_image.empty? ? reserved_image + constant_image : ""
      cons_size = cons_data.length
      @variable_offset = (reserved_image + constant_image).length
      @dynamic_area = @variable_offset + (@root_var_count * 2)
      
      
      build_class_hierarchy symbols
#puts
#puts "classes:"
#puts @classes.inspect
      build_cls_method_dispatcher
      asm = build_obj_method_dispatcher(head_size + libs_size, subs_size)
      dispatcher_code = Code.align(asm.code, 16)
      dispatcher_size = dispatcher_code.length
      mapper_method = asm.instructions.map{|x|x.to_s}.join("\r\n")
      #puts
      #puts "*** OBJECT METHOD MAPPER ***"
      #puts mapper_method
      #puts
      
      
      init_code = build_code_initializer(symbol_refs, codeset)
      init_size = init_code.length
      ds_offset = head_size + libs_size + subs_size + dispatcher_size + init_size + main_size
      
      if (extra_size = (ds_offset % 16)) > 0
        pad_count = 16 - extra_size
        
        if cons_size > 0
          main_code = main_code + (0.chr * pad_count)
          main_size = main_size + pad_count
        end
        
        ds_offset = ds_offset + pad_count
      end
      
      init_code[3, 2] = Converter.int2bin((ds_offset + @code_origin) >> 4, :word)
      
      
      main_offset = @code_origin + head_size + libs_size + subs_size + dispatcher_size
      head_code[1, 2] = Elang::Converter.int2bin(main_offset, :word)
      
      if libs_size > 0
        @kernel.functions.each do |k,v|
          v[:offset] += head_size
        end
      end
      
      symbols.items.each do |s|
        if s.is_a?(Function)
          s.offset = s.offset + head_size + libs_size
        end
      end
      
      resolve_references :subs, subs_code, symbol_refs, head_size + libs_size
      resolve_references :init, init_code, symbol_refs, head_size + libs_size + subs_size + dispatcher_size
      resolve_references :main, main_code, symbol_refs, head_size + libs_size + subs_size + dispatcher_size + init_size
      
      head_code + libs_code + subs_code + dispatcher_code + init_code + main_code + cons_data
    end
  end
end
