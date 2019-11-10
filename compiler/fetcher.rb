module Elang
  class Fetcher
    attr_reader :code, :char_pos, :code_len
    
    def init(code)
      @code = code
      @char_pos = 0
      @code_len = code.length
    end
    def char_pos=(value)
      if !@code.is_a?(String)
        raise "Fetcher#code must be a string."
      elsif !(0...@code.length).include?(value)
        raise "Fetcher#char_pos= => Parameter 'value' must be in (0...#{@code_len})."
      else
        @char_pos = value
      end
    end
    def current
      @code[@char_pos]
    end
    def next(offset = 1)
      if (@char_pos + offset) < @code_len
        @code[@char_pos + offset]
      end
    end
    def has_more?
      @code.is_a?(String) && (@char_pos <= (@code.length - 1))
    end
    def fetch(&block)
      if (0...@code_len).include?(@char_pos)
        if !block_given?
          char = @code[@char_pos]
          @char_pos += 1
          char
        else
          text = ""
          
          while @char_pos < @code_len
            if yield(@char_pos, char = @code[@char_pos])
              text << char
              @char_pos += 1
            else
              break
            end
          end
          
          text
        end
      end
    end
    def fetch_line
      if cp = @code.index("\r\n", @char_pos)
        tx = @code[@char_pos..(cp + 1)]
        @char_pos = cp + 2
        tx
      else
        tx = @code[@char_pos..-1]
        @char_pos = @code_len + 1
        tx
      end
    end
  end
end
