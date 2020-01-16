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
      
      if @fun.nil?
        fn = ""
      elsif @fun.is_a?(ClassFunction)
        fn = "#" + @fun.name
      else
        fn = "." + @fun.name
      end
      
      "#{cn}#{fn}"
    end
  end
end
