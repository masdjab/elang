module Elang
  class RelocationItem
    attr_accessor :function, :code_set, :location
    def initialize(function, code_set, location)
      @function = function
      @code_set = code_set
      @location = location
    end
  end
end
