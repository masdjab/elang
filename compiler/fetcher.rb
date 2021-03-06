module Elang
  class Fetcher
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
      at = at ? at : @pos
      !empty? && (0...@len).include?(at) ? @items[at] : nil
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
      temp = element
      @pos += 1
      temp
    end
  end
end
