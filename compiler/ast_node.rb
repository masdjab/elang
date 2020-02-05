module Elang
  class AstNode
    attr_reader   :row, :col
    attr_accessor :type, :text
    
    def initialize(row, col, type, text)
      @row = row
      @col = col
      @type = type
      @text = text
    end
  end
end
