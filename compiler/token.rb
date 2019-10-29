module Elang
  class Token
    attr_accessor :row, :col, :text
    def initialize(row, col, text)
      @row = row
      @col = col
      @text = text
    end
  end
end
