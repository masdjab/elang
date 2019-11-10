module Elang
  class Token
    attr_accessor :row, :col, :type, :text
    def initialize(row, col, type, text)
      @row = row
      @col = col
      @type = type
      @text = text
    end
  end
end
