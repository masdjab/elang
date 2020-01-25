require './utils/converter'

module Elang
  class Linker
    private
    def initialize
      @system_functions = {}
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
            elsif symbol.is_a?(Variable)
              resolve_value = (symbol.index - 1) * 2
              code[ref.location, 2] = Utils::Converter.int_to_word(resolve_value)
            elsif symbol.is_a?(FunctionParameter)
              resolve_value = (symbol.index + 2) * 2
              code[ref.location, 1] = Utils::Converter.int_to_byte(resolve_value)
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
            else
              raise "Cannot resolve reference to symbol of type '#{symbol.class}'"
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
      
      @library_code = buff[head_size...-1]
    end
    def link(codeset)
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
