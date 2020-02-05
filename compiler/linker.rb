require './utils/converter'
require './compiler/codeset_tool'
require './compiler/assembly_instruction'
require './compiler/assembly_code_builder'

module Elang
  class Linker
    HEAP_SIZE = 0x8000
    
    private
    def initialize
      @code_origin = 0x100
      @system_functions = {}
      @classes = {}
      @function_names = []
      @library_code = ""
      @dispatcher_offset = 0
      @string_constants = {}
      @cons_data_size = 0
    end
    def hex2bin(h)
      Utils::Converter.hex_to_bin(h)
    end
    def asm(code = "", desc = "")
      Assembly::Instruction.new(code, desc)
    end
    def align_code(code, align_size = 16)
      if (extra_size = (code.length % 16)) > 0
        code = code + (0.chr * (16 - extra_size))
      end
      
      code
    end
    def build_string_constants(codeset)
      cons = {}
      offs = 0
      
      codeset.symbols.items.each do |s|
        if s.is_a?(Constant)
          text = s.value
          
          if (text[0] == text[-1]) && ("\"'".index(text[0]))
            text = text[1...-1]
          end
          
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
        lgth = Utils::Converter.int_to_word(v[:length])
        cons << "#{lgth}#{v[:text]}"
      end
      
      cons
    end
    def build_code_initializer(codeset)
      rv_heap_size = Utils::Converter.int_to_whex_be(HEAP_SIZE)
      
      init_cmnd = 
        [
          "8CC8",                     # mov ax, cs
          "050000",                   # add ax, 0
          "8ED0",                     # mov ss, ax
          "8ED8",                     # mov ds, ax
          "B8#{rv_heap_size}50",      # push heap_size
          "B8000050",                 # push dynamic_area
          "E80000",                   # call mem_block_init
          "A30000"                    # mov [first_block], ax
        ]
      
      root_scope = Scope.new
      first_block = codeset.symbols.items.find{|x|x.is_a?(Variable) && x.scope.root? && (x.name == "first_block")}
      dynamic_area = codeset.symbols.items.find{|x|x.is_a?(Variable) && x.scope.root? && (x.name == "dynamic_area")}
      
      codeset.symbol_refs << VariableRef.new(dynamic_area, root_scope, 14, :init)
      codeset.symbol_refs << FunctionRef.new(SystemFunction.new("mem_block_init"), root_scope, 18, :init)
      codeset.symbol_refs << VariableRef.new(first_block, root_scope, 21, :init)
      
      hex2bin init_cmnd.join
    end
    def build_class_hierarchy(codeset)
      cs_tool = CodesetTool.new(codeset)
      @function_names = cs_tool.get_function_names
      @classes = cs_tool.get_classes_hierarchy
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
      asmcode << asm("C3", "  ret")
      
      code_label = "handle_method_not_found"
      code_offset[code_label] = asmcode.code.length
      asmcode << asm("", "#{code_label}:")
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
          func_address = Utils::Converter.int_to_whex_rev(@code_origin + subs_offset + f[:offset]).upcase
          asmcode << asm("83F8" + Utils::Converter.int_to_bhex_rev(f[:id]) + "7504", "  cmp ax, #{f[:id]}; jnz + 2")
          asmcode << asm("B8#{func_address}C3", "  mov ax, #{key.downcase}_obj_#{f[:name]}; ret")
        end
        
        if cls[:parent]
          code_label = "first_method_#{cls[:parent].downcase}"
          jump_distance = code_offset[code_label] - (asmcode.code.length + 3)
          jump_target = Utils::Converter.int_to_whex_rev(jump_distance).upcase
          asmcode << asm("E9#{jump_target}", "  jmp #{code_label}")
        else
          code_label = "handle_method_not_found"
          code_address = @code_origin + dispatcher_offset + code_offset[code_label]
          ax_value = Utils::Converter.int_to_whex_rev(code_address).upcase
          asmcode << asm("B8#{ax_value}C3", "  mov ax, #{code_label}; ret")
        end
      end
      
      
      asmcode << asm()
      code_label = "find_obj_method_address"
      code_offset[code_label] = asmcode.code.length
      asmcode << asm("", "#{code_label}:")
      
      @classes.each do |key, cls|
        asmcode << asm("83F8" + Utils::Converter.int_to_bhex_rev(cls[:clsid]).upcase, "  cmp ax, #{cls[:clsid]}")
        code_label = "method_selector_#{key.downcase}"
        jump_distance = code_offset[code_label] - (asmcode.code.length + 4)
        jump_target = Utils::Converter.int_to_whex_rev(jump_distance).upcase
        asmcode << asm("0F84#{jump_target}", "  jz #{code_label}")
      end
      
      code_label = "handle_invalid_class_id"
      func_address = @code_origin + dispatcher_offset + code_offset[code_label]
      ax_value = Utils::Converter.int_to_whex_rev(func_address).upcase
      asmcode << asm("B8#{ax_value}C3", "  mov ax, #{code_label}; ret")
      asmcode << asm()
      
      code_label = "_return_to_caller"
      code_offset[code_label] = asmcode.code.length
      asmcode << asm("", "#{code_label}:")
      asmcode << asm("50", "  push ax")
      asmcode << asm("56", "  push si")
      asmcode << asm("89EE", "  mov si, bp")
      asmcode << asm("8B4608", "  mov ax, [bp + 8]")
      asmcode << asm("83C004", "  add ax, 4")
      asmcode << asm("D1E0", "  shl ax, 1")
      asmcode << asm("01C6", "  add si, ax")
      asmcode << asm("8B4602", "  mov ax, [bp + 2]")
      asmcode << asm("87EE", "  xchg bp, si")
      asmcode << asm("894600", "  mov [bp], ax")
      asmcode << asm("87EE", "  xchg bp, si")
      asmcode << asm("897602", "  mov [bp + 2], si")
      asmcode << asm("5E", "  pop si")
      asmcode << asm("58", "  pop ax")
      asmcode << asm("5D", "  pop bp")
      asmcode << asm("5C", "  pop sp")
      asmcode << asm("C3", "  ret")
      
      asmcode << asm()
      code_label = "dispatch_obj_method"
      code_offset[code_label] = asmcode.code.length
      asmcode << asm("", "#{code_label}:")
      asmcode << asm("55", "  push bp")
      asmcode << asm("89E5", "  mov bp, sp")
      code_label = "_return_to_caller"
      code_address = @code_origin + dispatcher_offset + code_offset[code_label]
      ax_value = Utils::Converter.int_to_whex_rev(code_address).upcase
      asmcode << asm("B8#{ax_value}", "  mov ax, #{code_label}")
      asmcode << asm("50", "  push ax")
      asmcode << asm()
      
      asmcode << asm("56", "  push si")
      asmcode << asm("8B7604", "  mov si, [bp + 4]")
      asmcode << asm("8B04", "  mov ax, [si]")
      asmcode << asm("5E", "  pop si")
      code_label = "find_obj_method_address"
      call_distance = code_offset[code_label] - (asmcode.code.length + 3)
      call_target = Utils::Converter.int_to_whex_rev(call_distance).upcase
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
              code[ref.location, 2] = Utils::Converter.int_to_word(resolve_value)
            elsif symbol.is_a?(FunctionParameter)
              arg_offset = symbol.scope.cls ? 3 : 0
              resolve_value = (arg_offset + symbol.index + 2) * 2
              code[ref.location, 1] = Utils::Converter.int_to_byte(resolve_value)
            elsif symbol.is_a?(Variable)
              resolve_value = @cons_data_size + ((symbol.index - 1) * 2)
              code[ref.location, 2] = Utils::Converter.int_to_word(resolve_value)
            elsif symbol.is_a?(InstanceVariable)
              if (clsinfo = @classes[symbol.scope.cls]).nil?
                raise "Cannot find class '#{symbol.scope.cls}' in class info list"
              elsif (index = clsinfo[:i_vars].index(symbol.name)).nil?
                raise "Cannot find instance variable '#{symbol.name}' in '#{symbol.scope.cls}' class info"
              else
                code[ref.location, 2] = Utils::Converter.int_to_word(index)
              end
            elsif symbol.is_a?(Function)
              resolve_value = symbol.offset - (origin + ref.location + 2)
              code[ref.location, 2] = Utils::Converter.int_to_word(resolve_value)
            elsif symbol.is_a?(SystemFunction)
              if symbol.name == "_send_to_object"
                resolve_value = @dispatcher_offset - (origin + ref.location + 2)
                code[ref.location, 2] = Utils::Converter.int_to_word(resolve_value)
              elsif sys_function = @system_functions[symbol.name.to_s]
                resolve_value = sys_function[:offset] - (origin + ref.location + 2)
                code[ref.location, 2] = Utils::Converter.int_to_word(resolve_value)
              else
                raise "Undefined system function '#{symbol.name}'"
              end
            elsif symbol.is_a?(FunctionId)
              resolve_value = @function_names.index(symbol.name) + 1
              code[ref.location, 2] = Utils::Converter.int_to_word(resolve_value)
            elsif symbol.is_a?(Class)
puts "Resolving class '#{symbol.name}', index: #{symbol.index}"
            else
              raise "Cannot resolve reference to symbol of type '#{symbol.class}' => #{ref.inspect}"
            end
          end
        end
      end
    end
    
    public
    def load_library(libfile)
      file = File.new(libfile, "rb")
      buff = file.read
      file.close
      
      head_size = Elang::Utils::Converter.word_to_int(buff[0, 2])
      func_count = Elang::Utils::Converter.word_to_int(buff[2, 2])
      
      read_offset = 4
      (0...func_count).each do |i|
        func_address = Elang::Utils::Converter.word_to_int(buff[read_offset, 2]) - head_size
        name_length = Elang::Utils::Converter.word_to_int(buff[read_offset + 2, 2])
        func_name = buff[read_offset + 4, name_length]
        @system_functions[func_name] = {name: func_name, offset: func_address}
        read_offset = read_offset + name_length + 4
      end
      
      @library_code = align_code(buff[head_size...-1], 16)
    end
    def link(codeset)
      head_code = align_code(hex2bin("B8000050C3"), 16)
      libs_code = @library_code
      subs_code = align_code(codeset.subs_code, 16)
      main_code = codeset.main_code + Elang::Utils::Converter.hex_to_bin("CD20")
      head_size = head_code.length
      libs_size = libs_code.length
      subs_size = subs_code.length
      main_size = main_code.length
      
      @string_constants = build_string_constants(codeset)
      cons_data = align_code(build_constant_data(@string_constants), 16)
      @cons_data_size = cons_size = cons_data.length
      
      build_class_hierarchy codeset
puts
puts "classes:"
puts @classes.inspect
      build_cls_method_dispatcher
      asm = build_obj_method_dispatcher(head_size + libs_size, subs_size)
      dispatcher_code = align_code(asm.code, 16)
      dispatcher_size = dispatcher_code.length
      mapper_method = asm.instructions.map{|x|x.to_s}.join("\r\n")
      puts
      puts "*** OBJECT METHOD MAPPER ***"
      puts mapper_method
      puts
      
      
      init_code = build_code_initializer(codeset)
      init_size = init_code.length
      ds_offset = head_size + libs_size + subs_size + dispatcher_size + init_size + main_size
      
      if (extra_size = (ds_offset % 16)) > 0
        pad_count = 16 - extra_size
        main_code = main_code + (0.chr * pad_count)
        main_size = main_size + pad_count
        ds_offset = ds_offset + pad_count
      end
      
      init_code[3, 2] = Utils::Converter.int_to_word((ds_offset + @code_origin) >> 4)
      
      
      main_offset = @code_origin + head_size + libs_size + subs_size + dispatcher_size
      head_code[1, 2] = Elang::Utils::Converter.int_to_word(main_offset)
      
      if libs_size > 0
        @system_functions.each do |k,v|
          v[:offset] += head_size
        end
      end
      
      codeset.symbols.items.each do |s|
        if s.is_a?(Function)
          s.offset = s.offset + head_size + libs_size
        end
      end
      
      resolve_references :subs, subs_code, codeset.symbol_refs, head_size + libs_size
      resolve_references :init, init_code, codeset.symbol_refs, head_size + libs_size + subs_size + dispatcher_size
      resolve_references :main, main_code, codeset.symbol_refs, head_size + libs_size + subs_size + dispatcher_size + init_size
      
      head_code + libs_code + subs_code + dispatcher_code + init_code + main_code + cons_data
    end
  end
end
