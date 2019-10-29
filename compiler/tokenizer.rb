require './compiler/token'

module Elang
  class Tokenizer
    # class responsibility:
    # convert from source to tokens
    
    private
    def raw_token(pos, text)
      {pos: pos, text: text}
    end
    def fetch(code, pos, &block)
      text = ""
      crt_pos = pos
      text_len = code.length
      
      while (pos...text_len).include?(crt_pos)
        if yield(crt_pos, char = code[crt_pos])
          text << char
          crt_pos += 1
        else
          break
        end
      end
      
      text
    end
    def parse_number(code, pos)
      raw_token(pos, fetch(code, pos){|px, cx|'0123456789'.index(cx)})
    end
    def parse_string(code, pos)
      quote = fetch(code, pos){|px, cx|'\'"'.index(cx)}
      
      text = 
        fetch(code, pos) do |px, cx|
          if (code[px - 1] == quote) && ((px - 1) > pos) && (code[px - 2] != "\\")
            false
          else
            true
          end
        end
      
      raw_token(pos, text)
    end
    def parse_identifier(code, pos)
      text = 
        fetch(code, pos) do |px, cx|
          'abcdefghijklmnopqrstuvwxyz_'.index(cx.downcase)
        end
      
      raw_token(pos, text)
    end
    def parse_punctuation(code, pos)
      raw_token(pos, code[pos])
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
      
      if !code.empty?
        raw_tokens = []
        code_len = code.length
        char_pos = 0
        
        while (0...code_len).include?(char_pos)
          current_char = code[char_pos]
          
          if '0123456789'.index(current_char)
            token = parse_number(code, char_pos)
          elsif '\'"'.index(current_char)
            token = parse_string(code, char_pos)
          elsif 'abcdefghijklmnopqrstuvwxyz_'.index(current_char.downcase)
            token = parse_identifier(code, char_pos)
          else
            token = parse_punctuation(code, char_pos)
          end
          
          raw_tokens << token if token
          char_pos += token[:text].length
        end
        
        set_line_numbers raw_tokens, detect_lines(code)
        tokens = raw_tokens.map{|x|Token.new(x[:row], x[:col], x[:text])}
      end
      
      tokens
    end
  end
end
