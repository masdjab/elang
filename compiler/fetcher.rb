module Elang
  class Fetcher
    attr_reader :code, :char_pos, :code_len
    
    def init(code)
      @code = code
      @char_pos = 0
      @code_len = code.length
    end
    def fetch(&block)
      if !block_given?
        char = @code[@char_pos]
        @char_pos += 1
        char
      elsif (0...@code_len).include?(@char_pos)
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
end
