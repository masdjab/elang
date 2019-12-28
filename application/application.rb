require './application/code_container'
require './application/constant'
require './application/variable'
require './application/symbol_reference'
require './application/class'
require './application/function'

module Elang
  class EApplication
    attr_accessor :origin, :functions, :main, :variables, :constants
    
    def initialize
      @origin = 0
      @classes = []
      @functions = []
      @main = ""
      @variables = []
      @constants = []
      @references = []
    end
  end
end
