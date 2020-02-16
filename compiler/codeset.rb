require './compiler/symbols'

module Elang
  class CodeSet
    attr_reader   :symbols, :symbol_refs, :main_code, :subs_code, :code_branch
    attr_accessor :code_lines
    
    def initialize
      @symbols = Symbols.new
      @symbol_refs = []
      @main_code = ""
      @subs_code = ""
      @code_lines = []
      
      enter_subs
      leave_subs
    end
    def enter_subs
      @code_branch = @subs_code
    end
    def leave_subs
      @code_branch = @main_code
    end
    def append_code(code)
      @code_branch << code if !code.empty?
    end
  end
end
