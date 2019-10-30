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
    def char_pos
      @fetcher.char_pos
    end
    def fetch(&block)
      @fetcher.fetch(&block)
    end
    def parse_number
      raw_token char_pos, fetch{|px, cx|NUMBER.index(cx)}
    end
    #def parse_string(code, pos)
    #  quote = fetch(code, pos){|px, cx|'\'"'.index(cx)}
      
    #  text = 
    #    fetch(code, pos) do |px, cx|
    #      if (code[px - 1] == quote) && ((px - 1) > pos) && (code[px - 2] != "\\")
    #        false
    #      else
    #        true
    #      end
    #    end
      
    #  raw_token(pos, text)
    #end
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
        code_len = code.length
        char_pos = 0
        
        while (0...code_len).include?(char_pos)
          current_char = code[char_pos]
          
          if NUMBER.index(current_char)
            token = parse_number
          #elsif '\'"'.index(current_char)
          #  token = parse_string(code, char_pos)
          elsif IDENTIFIER.index(current_char.downcase)
            token = parse_identifier
          else
            token = parse_punctuation
          end
          
          raw_tokens << token
          char_pos += token[:text].length
        end
        
        set_line_numbers raw_tokens, detect_lines(code)
        tokens = raw_tokens.map{|x|Token.new(x[:row], x[:col], x[:text])}
      end
      
      tokens
    end
  end
end
