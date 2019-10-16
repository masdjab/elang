require './application/code_container'
require './application/constant'
require './application/variable'
require './application/relocation_item'
require './application/relocation_initializer'
require './application/symbol_reference'
require './application/function'
#require './main_code'

module Elang
  class EApplication
    attr_reader \
      :name, :functions, :main, :subs, :variables, :constants
      #:references
    attr_reader :relocations
    
    def initialize(name)
      @name = name
      @functions = []
      @main = ICodeContainer.new
      @subs = ICodeContainer.new
      @variables = []
      @constants = []
      #@references = []
      @relocations = []
    end
  end
end
