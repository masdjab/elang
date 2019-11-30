module Elang
  class FetcherV2
    attr_reader :text, :len, :pos
    def initialize(text)
      @text = text
      @pos  = 0
      @len  = text.length
    end
    def empty?
      @text.empty?
    end
    def eob?
      @pos == @len - 1
    end
    def char(at = nil)
      cpos = at ? at : @pos
      !empty? && (0...@len).include?(cpos) ? @text[cpos] : nil
    end
    def next
      !empty? && !eob? ? @text[@pos + 1] : nil
    end
    def prev
      !empty? && (@pos > 0) ? @text[@pos - 1] : nil
    end
    def forward
      @pos += 1
    end
    def back
      @pos -= 1
    end
    def fetch
      temp = char
      @pos += 1
      temp
    end
  end
end
