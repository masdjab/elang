require './compiler/symbols'

module Elang
  class CodeSet
    attr_reader :symbols, :symbol_refs, :binary_code
    
    def initialize
      @symbols = Symbols.new
      @symbol_refs = []
      @binary_code = ""
    end
    def append_code(code)
      @binary_code << code if !code.empty?
    end
  end
end
