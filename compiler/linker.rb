require './utils/converter'

module Elang
  class Linker
    def hex2bin(h)
      Utils::Converter.hex_to_bin(h)
    end
    def resolve_references(code, refs)
      if !code.empty?
        refs.each do |ref|
          symbol = ref.symbol
          
          if symbol.is_a?(Constant)
            resolve_value = (symbol.index - 1) * 2
            code[ref.location, 2] = Utils::Converter.int_to_word(resolve_value)
          elsif symbol.is_a?(Variable)
            resolve_value = (symbol.index - 1) * 2
            code[ref.location, 2] = Utils::Converter.int_to_word(resolve_value)
          elsif symbol.is_a?(Function)
            resolve_value = symbol.offset - (ref.location + 2)
            code[ref.location, 2] = Utils::Converter.int_to_word(resolve_value)
          else
            raise "Cannot resolve reference to symbol of type '#{symbol.class}'"
          end
        end
      end
    end
    def link(codeset)
      # constants, symbols, symbol_refs
      main_code = codeset.main_code
      subs_code = codeset.subs_code
      
      if !subs_code.empty?
        head_code = hex2bin("E80000")
      else
        head_code = ""
      end
      
      resolve_references main_code, codeset.symbol_refs
      resolve_references subs_code, codeset.symbol_refs
      
      head_code + subs_code + main_code
    end
  end
end
