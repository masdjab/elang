module Elang
  class Scope
    attr_accessor :cls, :fun
    
    def initialize(cls = nil, fun = nil)
      @cls = cls
      @fun = fun
    end
    def root?
      @cls.nil? && @fun.nil?
    end
    def to_s
      cn = @cls ? @cls : ""
      fn = @fun ? ".#{@fun}" : ""
      "#{cn}#{fn}"
    end
  end
end
