module Elang
  class Token
    attr_accessor :row, :col, :source, :type, :text
    def initialize(row, col, source, type, text)
      @row = row
      @col = col
      @source = source
      @type = type
      @text = text
    end
  end
end
