module Parser
  class Token
    WORD      = "w"
    COMMAND   = "c"
    NAME      = "n"
    NUMBER    = "u"
    STRING    = "s"
    SPACE     = " "
    OTHER     = "o"
    COMMENT   = "m"
    COLON     = ":"
    SEMICOLON = ";"
    
    attr_accessor :type, :value
    
    def initialize(type, value)
      @type = type
      @value = value
    end
  end
  
  class LineParser
    private
    def initialize(text)
      @buffer = text.lines
      @line_no = 0
      @line_len = 0
      @crt_line = ""
      @char_pos = 0
    end
    def fetch_whspace
      text = ""
      
      while (0...@line_len).include?(@char_pos)
        crtchr = @crt_line[@char_pos]
        if " \t".include?(crtchr)
          text = text + crtchr
          @char_pos = @char_pos + 1
        else
          break
        end
      end
      
      Token.new(Token::SPACE, text)
    end
    def fetch_number
      text = ""
      
      while (0...@line_len).include?(@char_pos)
        crtchr = @crt_line[@char_pos]
        if "0123456789".include?(crtchr)
          @char_pos = @char_pos + 1
          text = text + crtchr
        elsif crtchr == "-"
          if text.empty?
            @char_pos = @char_pos + 1
            text = text + crtchr
          else
            break
          end
        elsif crtchr == "."
          if text.index(".").nil?
            @char_pos = @char_pos + 1
            text = text + crtchr
          else
            break
          end
        elsif crtchr == "x"
          if text.length == 1
            @char_pos = @char_pos + 1
            text = text + crtchr
          else
            raise "Invalid number '#{text}'."
          end
        else
          break
        end
      end
      
      Token.new(Token::NUMBER, text)
    end
    def fetch_word
      text = ""
      
      while (0...@line_len).include?(@char_pos)
        crtchr = @crt_line[@char_pos]
        lwrchr = crtchr.downcase
        unless "abcdefghijklmnopqrstuvwxyz0123456789_".index(lwrchr).nil?
          text = text + crtchr
          @char_pos = @char_pos + 1
        else
          break
        end
      end
      
      Token.new(Token::WORD, text)
    end
    def fetch_string
      text = ""
      escp = false
      mtch = false
      
      while (0...@line_len).include?(@char_pos)
        crtchr = @crt_line[@char_pos]
        if escp
          @char_pos = @char_pos + 1
          text = text + crtchr
          escp = false
        elsif crtchr == "\\"
          @char_pos = @char_pos + 1
          escp = true
        elsif (crtchr == "\"") || (crtchr == "'")
          @char_pos = @char_pos + 1
          if text.empty?
            text = text + crtchr
          elsif crtchr == text[0]
            text = text + crtchr
            mtch = true
            break
          else
            text = text + crtchr
          end
        else
          @char_pos = @char_pos + 1
          text = text + crtchr
        end
      end
      
      raise "End quote expected." unless mtch
      
      Token.new(Token::STRING, text)
    end
    def fetch_line
      list = []
      @char_pos = 0
      
      while (0...@line_len).include?(@char_pos)
        oldp = @char_pos
        char = @crt_line[@char_pos]
        
        begin
          if " \t".index(char)
            tokn = fetch_whspace
          elsif "0123456789".index(char)
            tokn = fetch_number
          elsif "abcdefghijklmnopqrstuvwxyz_".index(char.downcase)
            tokn = fetch_word
          elsif (char == "\"") || (char == "'")
            tokn = fetch_string
          elsif char == "#"
            tokn = Token.new(Token::COMMENT, @crt_line[@char_pos..-1])
            @char_pos = @line_len
          elsif char == ":"
            tokn = Token.new(Token::COLON, char)
            @char_pos += 1
          elsif char == ";"
            tokn = Token.new(Token::SEMICOLON, char)
            @char_pos += 1
          else
            # invalid character
            @char_pos = @char_pos + 1
            tokn = Token.new(char, char)
          end
        rescue Exception => e
          raise "Error at line #{@line_no} col #{@char_pos}: #{e.message}"
        end
        
        if tokn
          list << tokn unless [Token::COMMENT].include?(tokn.type)
          break if tokn.type == Token::COMMENT
        else
          break
        end
      end
      
      list
    end
    
    public
    def eof?
      @line_no >= @buffer.length
    end
    def read_line
      if !eof?
        @line_no += 1
        @crt_line = @buffer[@line_no - 1]
        @line_len = @crt_line.length
        @crt_line
      end
    end
    def fetch_heredoc(marker)
    end
    def parse
      if !(temp = read_line.gsub(" ", "").gsub("\t", "")).nil?
        if (temp.length > 0) && (temp[0] != "#")
          fetch_line
        end
      end
    end
  end
end
