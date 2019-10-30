require './compiler/fetcher'
require './compiler/token'

module Elang
  class Tokenizer
    # class responsibility:
    # convert from source to tokens
    
    IDENTIFIER = 'abcdefghijklmnopqrstuvwxyz_'
    NUMBER = '0123456789'
    
    private
    def raw_token(pos, text)
      {pos: pos, text: text}
    end
    def code
      @fetcher.code
    end
    def code_len
      @fetcher.code_len
    end
    def char_pos
      @fetcher.char_pos
    end
    def current
      @fetcher.current
    end
    def fetch(&block)
      @fetcher.fetch(&block)
    end
    def fetch_line
      @fetcher.fetch_line
    end
    def parse_whitespace
      raw_token char_pos, fetch{|px, cx|" \t".index(cx)}
    end
    def parse_comment
      raw_token char_pos, fetch_line
    end
    def parse_number
      raw_token char_pos, fetch{|px, cx|NUMBER.index(cx)}
    end
    def parse_string
      pos = char_pos
      quote = fetch
      
      text = 
        fetch do |px, cx|
          if (code[px - 1] == quote) && ((px - 1) > pos) && (code[px - 2] != "\\")
            false
          else
            true
          end
        end
      
      raw_token pos, quote + text
    end
    def parse_identifier
      raw_token char_pos, fetch{|px, cx|IDENTIFIER.index(cx.downcase)}
    end
    def parse_punctuation
      raw_token char_pos, fetch
    end
    def detect_lines(code)
      pos = 0
      row = 1
      lines = []
      
      code.lines.each do |line|
        lines << {row: row, min: pos, max: pos + line.length - 1}
        row += 1
        pos += line.length
      end
      
      lines
    end
    def set_line_numbers(tokens, lines)
      tokens.each do |token|
        line = lines.find{|x|(x[:min]..x[:max]).include?(token[:pos])}
        token.merge!(row: line[:row], col: token[:pos] - line[:min] + 1)
      end
    end
    
    public
    def parse(code)
      tokens = []
      
      @fetcher = Fetcher.new
      @fetcher.init code
      
      if !code.empty?
        raw_tokens = []
        
        while @fetcher.has_more?
          current_char = current
          
          if " \t".index(current_char)
            token = parse_whitespace
          elsif current_char == "#"
            token = parse_comment
          elsif NUMBER.index(current_char)
            token = parse_number
          elsif '\'"'.index(current_char)
            token = parse_string
          elsif IDENTIFIER.index(current_char.downcase)
            token = parse_identifier
          else
            token = parse_punctuation
          end
          
          raw_tokens << token
        end
        
        set_line_numbers raw_tokens, detect_lines(code)
        tokens = raw_tokens.map{|x|Token.new(x[:row], x[:col], x[:text])}
      end
      
      tokens
    end
  end
end
