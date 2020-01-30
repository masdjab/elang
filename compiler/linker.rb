require './utils/converter'
require './compiler/codeset_tool'

module Elang
  class Linker
    private
    def initialize
      @system_functions = {}
      @classes = {}
      @library_code = ""
    end
    def hex2bin(h)
      Utils::Converter.hex_to_bin(h)
    end
    def resolve_references(type, code, refs, origin)
      if !code.empty?
        refs.each do |ref|
          if ref.code_type == type
            symbol = ref.symbol
            
            if symbol.is_a?(Constant)
              resolve_value = (symbol.index - 1) * 2
              code[ref.location, 2] = Utils::Converter.int_to_word(resolve_value)
            elsif symbol.is_a?(FunctionParameter)
              resolve_value = (symbol.index + 2) * 2
              code[ref.location, 1] = Utils::Converter.int_to_byte(resolve_value)
            elsif symbol.is_a?(Variable)
              resolve_value = (symbol.index - 1) * 2
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
              if (sys_function = @system_functions[symbol.name]).nil?
                raise "Undefined system function '#{symbol.name}'"
              else
                resolve_value = sys_function[:offset] - (origin + ref.location + 2)
                code[ref.location, 2] = Utils::Converter.int_to_word(resolve_value)
              end
            elsif symbol.is_a?(Class)
puts "Resolving class '#{symbol.name}', index: #{symbol.index}"
            else
              raise "Cannot resolve reference to symbol of type '#{symbol.class}'"
            end
          end
        end
      end
    end
    def build_class_hierarchy(codeset)
      cs_tool = CodesetTool.new(codeset)
      @classes = cs_tool.get_classes_hierarchy
    end
    def build_cls_method_dispatcher
      #(todo)#build class methods dispatcher
    end
    def build_obj_method_dispatcher
      code_offset = 0x200
      
      invalid_class_handler_hex = "C3"
      invalid_method_handler_hex = "C3"
      
      
      class_selector = []
      method_selector = []
      class_selector << ["56", "  push si"]
      class_selector << ["8B7604", "  mov si, [bp + 4]"]
      class_selector << ["8B04", "  mov ax, [si]"]
      class_selector << ["5E", "  pop si"]
      @classes.each do |key, cls|
        class_selector << ["83F800", "  cmp ax, #{cls[:clsid]}"]
        class_selector << ["0F840000", "  jz method_selector_#{key.downcase}"]
        method_selector << ["", "method_selector_#{key.downcase}:"]
        method_selector << ["8B4606", "  mov ax, [bp + 6]"]
        method_selector << ["", "first_method_#{key.downcase}:"]
        cls[:i_funs].each do |f|
          method_selector << ["83F800", "  cmp ax, #{f[:id]}"]
          method_selector << ["0F840000", "  jz #{key.downcase}_obj_#{f[:name]}"]
        end
        
        if cls[:parent]
          method_selector << ["E90000", "  jmp first_method_#{cls[:parent].downcase}"]
        else
          method_selector << ["E90000", "  jmp object_method_not_found"]
        end
      end
      class_selector << ["E90000", "  jmp invalid_class_id"]
      class_selector_mnemonic = class_selector.map{|x|x[1]}
      method_selector_mnemonic = method_selector.map{|x|x[1]}
      mapper_method = (class_selector_mnemonic + method_selector_mnemonic).join("\r\n")
      puts "object_method_mapper:"
      puts mapper_method
      
      
      hex_code = ""
      
      #(todo)#build object methods dispatcher
      
      #  ; args: object, method-id, args-count, *args
      hex_code += 
        [
          "5589E5"                #  push bp; mov bp, sp
        ].join
      
      hex_code += 
        [
          "B800005053"            #  mov ax, _dom_method_executed, push ax; push dx
          #  mov ax, [bp + 6]
          #  cmp ax, 1
          #  mov dx, obj_method_1_1
          #  jz _dom_method_set
          #  cmp ax, 2
          #  mov dx, obj_method_1_2
          #  jz _dom_method_set
          #  cmp ax, 3
          #  mov dx, obj_method_2_1
          #  jz _dom_method_set
          #  cmp ax, 4
          #  mov dx, obj_method_2_2
          #  jz _dom_method_set
          #  mov dx, obj_no_method
          #_dom_method_set:
          #  xchg ax, dx; pop dx; push ax; ret
        ].join
      
      #_dom_method_executed:
      hex_code += 
        [
          "505689EE",               #  push ax; push si; mov si, bp
          "8B460883C004D1E001C6",   #  mov ax, [bp + 8]; add ax, 4; shl ax, 1; add si, ax
          "8B460287EE894600",       #  mov ax, [bp + 2]; xchg bp, si; mov [bp], ax
          "87EE897602",             #  xchg bp, si; mov [bp + 2], si
          "5E585D",                 #  pop si; pop ax; pop bp
          "5CC3"                    #  pop sp; ret
        ].join
      
      hex2bin hex_code
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
      
      @library_code = buff[head_size...-1]
    end
    def link(codeset)
      build_class_hierarchy codeset
puts @classes.inspect
      build_cls_method_dispatcher
      build_obj_method_dispatcher
      
      main_code = codeset.main_code + Elang::Utils::Converter.hex_to_bin("CD20")
      libs_code = @library_code
      subs_code = codeset.subs_code
      libs_size = libs_code.length
      subs_size = subs_code.length
      
      if (libs_size + subs_size) > 0
        head_code = hex2bin("E9" + Elang::Utils::Converter.int_to_whex_be(libs_size + subs_size))
      else
        head_code = ""
      end
      
      head_size = head_code.length
      
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
      resolve_references :main, main_code, codeset.symbol_refs, head_size + libs_size + subs_size
      
      head_code + libs_code + subs_code + main_code
    end
  end
end
