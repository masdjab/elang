module Elang
  class Function
    PREDEFINED_FUNCTION_NAMES =
      [
        "+", "-", "*", "/", "&", "|", 
        "+=", "-=", "*=", "/=", "&=", "|=", 
        "==", "!=", "<", ">", "<=", ">=", 
        "initialize", "super", "nil?", "to_s", 
        "_get_byte_at", "_set_byte_at", 
        "_get_word_at", "_set_word_at"
      ]
    
    @@index = 0
    
    attr_accessor :offset
    attr_reader   :context, :scope, :receiver, :name, :params, :index
    def initialize(context, scope, receiver, name, params, offset)
      @index = @@index = @@index + 1
      @context = context
      @scope = scope
      @receiver = receiver
      @name = name
      @params = params
      @offset = offset
    end
    def self.reset_index
      @@index = 0
    end
  end
end
