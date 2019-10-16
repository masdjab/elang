require './code_container'
require './constant'
require './variable'
require './relocation_item'
require './relocation_initializer'
require './symbol_reference'
require './function'
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
