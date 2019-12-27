module Elang
  class FetcherV2
    attr_reader :items, :len, :pos
    def initialize(items)
      @items = items
      @pos  = 0
      @len  = items.length
    end
    def empty?
      @items.empty?
    end
    def eob?
      @pos == @len - 1
    end
    def element(at = nil)
      cpos = at ? at : @pos
      !empty? && (0...@len).include?(cpos) ? @items[cpos] : nil
    end
    def char(at = nil)
      # deprecated
      element(at)
    end
    def next
      !empty? && !eob? ? @items[@pos + 1] : nil
    end
    def prev
      !empty? && (@pos > 0) ? @items[@pos - 1] : nil
    end
    def last
      !empty? ? @items.last : nil
    end
    def fetch
      temp = char
      @pos += 1
      temp
    end
  end
end
