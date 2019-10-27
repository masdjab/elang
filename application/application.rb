# 345678901234567890123456789012345678901234567890123456789012345678901234567890

require './application/code_container'
require './application/constant'
require './application/variable'
require './application/symbol_reference'
require './application/class'
require './application/function'

module Elang
  class EApplication
    attr_accessor :origin, :functions, :main, :subs, :variables, :constants
    
    def initialize
      @origin = 0
      @classes = []
      @functions = []
      @main = ICodeContainer.new
      @subs = ICodeContainer.new
      @variables = []
      @constants = []
      @references = []
    end
  end
end
