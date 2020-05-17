module Elang
  class CodeBuffer
    attr_accessor :context, :data
    def initialize(context = nil, data = "")
      @context = context
      @data = data
    end
  end
  
  
  class CodeSection < CodeBuffer
    attr_reader   :name, :type
    def initialize(name, type, data = "")
      super(CodeContext.new(name), data)
      @name = name
      @type = type
    end
  end
end
