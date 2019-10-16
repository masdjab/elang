module Lexer
  class Position
    attr_accessor :line, :column
    
    def initialize(line, column)
      @line = line
      @column = column
    end
    def copy
      self.class.new(@line, @column)
    end
  end
  
  
  class Token
    attr_accessor :position, :type, :value
    
    def initialize(position, type, value)
      @position = position
      @type = type
      @value = value
    end
  end
  
  
  class Fetcher
    DIGITS  = "0123456789"
    LETTERS = "abcdefghijklmnopqrstuvwxyz"
    
    def initialize(source)
      @source = source
      @length = @source.length
      @offset = 0
      @position = Position.new(1, 1)
    end
    def eof?
      @offset >= @length
    end
    def fetch_char
      if (0...@length).include?(@offset)
        @source[@offset]
      end
    end
    def fetch_as(type, &block)
      if !eof?
        text = ""
        pos = @position.copy
        
        while !(char = fetch_char).nil?
          if yield(char, text)
            text = text + char
            @offset += 1
            @position.column += 1
          else
            break
          end
        end
        
        Token.new(pos, type, text)
      end
    end
    def fetch_char_as(type)
      if !eof?
        pos = @position.copy
        char = @source[@offset]
        @offset += 1
        @position.column += 1
        Token.new(pos, type, char)
      end
    end
    def fetch_space
      fetch_as(:space){|c,t|c == " "}
    end
    def fetch_tab
      fetch_as(:tab){|c,t|c == "\t"}
    end
    def fetch_digit
      fetch_as(:digit){|c,t|!DIGITS.index(c).nil?}
    end
    def fetch_identifier
      fetch_as(:letter) do |c,t|
        if (c == "@") && t.empty?
          true
        elsif !"abcdefghijklmnopqrstuvwxyz0123456789_:".index(c.downcase).nil?
          true
        else
          false
        end
      end
    end
    def fetch_string(marker)
      fetch_as(:string){|c,t|(t.length <= 2) || (t[-1] != marker)}
    end
    def fetch_equal
      fetch_as(:equal){|c,t|c == "="}
    end
    def fetch_comparator
      fetch_as(:comparator){|c,t|!"<=>!".index(c).nil?}
    end
    def fetch_logical
      fetch_as(:logical){|c,t|!"&|".index(c).nil?}
    end
    def fetch_comment
      fetch_as(:comment){|c,t|[13.chr, 10.chr].index(c).nil?}
    end
    def fetch
      if (0...@length).include?(@offset)
        char = @source[@offset]
        
        if char == " "
          fetch_space
        elsif char == "\t"
          fetch_tab
        elsif DIGITS.index(char)
          fetch_digit
        elsif "abcdefghijklmnopqrstuvwxyz0123456789:_".index(char.downcase)
          fetch_identifier
        elsif char == "@"
          fetch_identifier
        elsif "\"'".index(char)
          fetch_string char
        elsif "<=>!".index(char)
          fetch_comparator
        elsif "&|".index(char)
          fetch_logical
        elsif char == "#"
          fetch_comment
        elsif char == 13.chr
          fetch_char_as :cr
        elsif char == 10.chr
          t = fetch_char_as(:lf)
          @position = Position.new(@position.line + 1, 1)
          t
        else
          fetch_char_as :punct
        end
      end
    end
  end
end
