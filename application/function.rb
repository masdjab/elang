module Elang
  class EFunction
    attr_accessor :context, :name, :arguments, :body
    
    def initialize(context, name, options = {})
      @context = context
      @name = name
      @arguments = options.fetch(:arguments, [])
      @body = options.fetch(:body, "")
    end
  end
end
