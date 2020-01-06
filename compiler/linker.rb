require './utils/converter'

module Elang
  class Linker
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
            elsif symbol.is_a?(Function)
              resolve_value = symbol.offset - (origin + ref.location + 2)
              code[ref.location, 2] = Utils::Converter.int_to_word(resolve_value)
            else
              raise "Cannot resolve reference to symbol of type '#{symbol.class}'"
            end
          end
        end
      end
    end
    def link(codeset)
      # constants, symbols, symbol_refs
      main_code = codeset.main_code
      subs_code = codeset.subs_code
      
      if !subs_code.empty?
        head_code = hex2bin("E90000")
      else
        head_code = ""
      end
      
      head_size = head_code.length
      subs_size = subs_code.length
      
      if head_size > 0
        codeset.symbols.items.each do |s|
          s.offset += head_size if s.is_a?(Function)
        end
      end
      
      resolve_references :subs, subs_code, codeset.symbol_refs, 0
      resolve_references :main, main_code, codeset.symbol_refs, head_size + subs_size
      
      head_code + subs_code + main_code
    end
  end
end
