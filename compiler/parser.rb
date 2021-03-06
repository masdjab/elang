require_relative 'fetcher'
require_relative 'token'

module Elang
  class Parser
    # syntax to be supported:
    # medium priority:
    # - require
    # - import module_name
    # - from module_name import symbol1, symbol2, ...
    # low priority:
    # - expression if condition
    # - expression unless condition
    # - single/multi assignment
    
    NUMBERS = "0123456789"
    HEX_NUMS = "#{NUMBERS}abcdef"
    LETTERS = "abcdefghijklmnopqrstuvwxyz"
    IDENTIFIER = "#{LETTERS}#{NUMBERS}_"
    
    def initialize
      @source = nil
      @fetcher = Fetcher.new("")
    end
    def _pos_to_row_col(pos)
      if line = @source.lines.find{|x|(x.min..x.max).include?(pos)}
        {row: line.row, col: pos - line.min + 1}
      else
        {row: 0, col: 0}
      end
    end
    def _set_line_numbers(tokens)
      tokens.each do |token|
        if line = _pos_to_row_col(token[:pos])
          token.merge!(row: line[:row], col: line[:col])
        end
      end
    end
    def _code_snapshot(pos, anchor, ellipsis = true)
      "#{@fetcher.element[anchor, 10]}#{ellipsis ? "..." : ""}"
    end
    def _pos_info(pos)
      pos = _pos_to_row_col(pos) if pos.is_a?(Integer)
      "#{pos[:row]}:#{pos[:col]}"
    end
    def _create_parse_error(rowcol, message)
      ParsingError.new(message, rowcol[:row], rowcol[:col], @source.lines)
    end
    def _throw_parse_error(pos, message)
      rowcol = _pos_to_row_col(pos)
      raise _create_parse_error(rowcol, "#{message} at #{_pos_info(rowcol)}.")
    end
    def _throw_invalid_char(pos, anchor, char)
      rowcol = _pos_to_row_col(pos)
      e_info = "Invalid char '#{char}' at #{_pos_info(rowcol)} #{_code_snapshot(pos, anchor)}"
      raise _create_parse_error(rowcol, e_info)
    end
    def _throw_unexpected_end_of_file(pos, anchor)
      e_info = "Unexpected end of file at #{_pos_info(pos)}: #{_code_snapshot(pos, anchor)}"
      _throw_parse_error pos, e_info
    end
    def _raw_token(pos, type, text)
      {pos: pos, type: type, text: text}
    end
    def _parse_whitespace
      cpos = @fetcher.pos
      text = ""
      
      while char = @fetcher.element
        if " \t".index(char)
          text << @fetcher.fetch
        else
          break
        end
      end
      
      _raw_token cpos, :whitespace, text
    end
    def _parse_linefeed
      lnfd = 13.chr + 10.chr
      type = nil
      cpos = @fetcher.pos
      char = @fetcher.element
      text = ""
      
      if char == lnfd[0]
        text << @fetcher.fetch
        
        if @fetcher.element == lnfd[1]
          text << @fetcher.fetch
          type = :crlf
        else
          type = :cr
        end
      elsif char == lnfd[1]
        text << @fetcher.fetch
        type = :lf
      end
      
      _raw_token cpos, type, text
    end
    def _parse_comment
      cpos = @fetcher.pos
      text = @fetcher.fetch
      
      while char = @fetcher.element
        if (13.chr + 10.chr).index(char)
          break
        else
          text << @fetcher.fetch
        end
      end
      
      _raw_token cpos, :comment, text
    end
    def _parse_identifier
      cpos = @fetcher.pos
      text = ""
      
      while char = @fetcher.element
        if IDENTIFIER.index(char.downcase)
          text << @fetcher.fetch
        else
          break
        end
      end
      
      _raw_token cpos, :identifier, text
    end
    def _parse_string
      text   = ""
      cpos   = @fetcher.pos
      quote  = @fetcher.element
      escape = false
      
      while char = @fetcher.fetch
        if (char == quote) && !text.empty? && !escape
          text << char
          escape = false
          break
        elsif char == "\\"
          text << char
          escape = true
        else
          text << char
          escape = false
        end
      end
      
      _raw_token cpos, :string, text[1...-1]
    end
    def _parse_number
      text = ""
      cpos = @fetcher.pos
      
      while char = @fetcher.element
        if NUMBERS.index(char)
          text << @fetcher.fetch
        elsif char == "."
          if (text.length >= 2) && (text[0..1] == "0x")
            _throw_invalid_char @fetcher.pos, cpos, char
          elsif text.index(".").nil?
            if nc = @fetcher.next
              if NUMBERS.index(nc)
                text << @fetcher.fetch
              else
                break
              end
            else
              _throw_unexpected_end_of_file @fetcher.pos, cpos
            end
          else
            _throw_invalid_char @fetcher.pos, cpos, char
          end
        elsif char == "x"
          if text == "0"
            if (nc = @fetcher.next).nil?
              _throw_unexpected_end_of_file @fetcher.pos, cpos
            elsif HEX_NUMS.index(nc.downcase).nil?
              _throw_invalid_char @fetcher.pos, cpos, char
            else
              text << @fetcher.fetch
            end
          else
            _throw_invalid_char @fetcher.pos, cpos, char
          end
        elsif "abcdef".index(char.downcase)
          if (text.length >= 2) && (text[0..1].downcase == "0x")
            text << @fetcher.fetch
          else
            _throw_invalid_char @fetcher.pos, cpos, char
          end
        elsif IDENTIFIER.index(char.downcase)
          _throw_invalid_char @fetcher.pos, cpos, char
        else
          break
        end
      end
      
      _raw_token cpos, :number, text
    end
    def _parse_plus
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :plus
      
      if @fetcher.element == "="
        text << @fetcher.fetch
        type = :plus_assign
      end
      
      _raw_token cpos, type, text
    end
    def _parse_minus
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :minus
      
      if @fetcher.element == "="
        text << @fetcher.fetch
        type = :minus_assign
      end
      
      _raw_token cpos, type, text
    end
    def _parse_star
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :star
      
      if @fetcher.element == "="
        text << @fetcher.fetch
        type = :star_assign
      end
      
      _raw_token cpos, type, text
    end
    def _parse_slash
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :slash
      
      if @fetcher.element == "="
        text << @fetcher.fetch
        type = :slash_assign
      end
      
      _raw_token cpos, type, text
    end
    def _parse_and
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :and
      
      if @fetcher.element == "="
        text << @fetcher.fetch
        type = :and_assign
      elsif @fetcher.element == "&"
        text << @fetcher.fetch
        type = :andand
      end
      
      _raw_token cpos, type, text
    end
    def _parse_or
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :or
      
      if @fetcher.element == "="
        text << @fetcher.fetch
        type = :or_assign
      elsif @fetcher.element == "|"
        text << @fetcher.fetch
        type = :oror
      end
      
      _raw_token cpos, type, text
    end
    def _parse_not
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :exclamation
      
      if @fetcher.element == "="
        text << @fetcher.fetch
        type = :not_equal
      end
      
      _raw_token cpos, type, text
    end
    def _parse_equal
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :assign
      
      if @fetcher.element == "="
        text << @fetcher.fetch
        type = :equal
      elsif @fetcher.element == ">"
        text << @fetcher.fetch
        type = :to
      end
      
      _raw_token cpos, type, text
    end
    def _parse_less_than
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :lt
      
      if @fetcher.element == "="
        text << @fetcher.fetch
        type = :le
      elsif @fetcher.element == "<"
        text << @fetcher.fetch
        type = :ltlt
      end
      
      _raw_token cpos, type, text
    end
    def _parse_greater_than
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :gt
      
      if @fetcher.element == "="
        text << @fetcher.fetch
        type = :ge
      elsif @fetcher.element == ">"
        text << @fetcher.fetch
        type = :gtgt
      end
      
      _raw_token cpos, type, text
    end
    def _parse_logical
      cpos = @fetcher.pos
      tmap = {"&" => :and, "&&" => :andand, "|" => :or, "||" => :oror}
      text = @fetcher.fetch
      
      if @fetcher.element == text
        text << @fetcher.fetch
      end
      
      _raw_token cpos, tmap[text], text
    end
    def _parse_dot
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :dot
      
      if @fetcher.element == "."
        text << @fetcher.fetch
        type = :dotdot
        
        if @fetcher.element == "."
          text << @fetcher.fetch
          type = :dotdotdot
        end
      end
      
      _raw_token cpos, type, text
    end
    def _parse_punctuation
      punct_types = 
        {
          ","   => :comma, 
          ":"   => :colon, 
          ";"   => :semicolon, 
          "("   => :lbrk, 
          ")"   => :rbrk, 
          "["   => :lsbrk, 
          "]"   => :rsbrk, 
          "{"   => :lcbrk, 
          "}"   => :rcbrk, 
          "\\"  => :bslash, 
          "?"   => :question, 
          "!"   => :exclamation, 
          "@"   => :at, 
          "~"   => :tilde, 
          "`"   => :bquote, 
          "$"   => :dollar, 
          "%"   => :percent, 
          "^"   => :xor
        }
      
      cpos = @fetcher.pos
      char = @fetcher.fetch
      _raw_token(cpos, punct_types.fetch(char, :punct), char)
    end
    def detect_lines(code)
      pos = 0
      row = 1
      lines = []
      
      code.lines.each do |line|
        lines << {row: row, min: pos, max: pos + line.length - 1, text: line}
        row += 1
        pos += line.length
      end
      
      lines
    end
    def parse(source)
      @source = source
      code = @source.text
      @fetcher = Fetcher.new(code)
      raw_tokens = []
      
      while char = @fetcher.element
        if " \t".index(char)
          raw_tokens << _parse_whitespace
        elsif [13.chr, 10.chr].include?(char)
          raw_tokens << _parse_linefeed
        elsif char == "#"
          raw_tokens << _parse_comment
        elsif "#{LETTERS}_".index(char.downcase)
          raw_tokens << _parse_identifier
        elsif "'\"".index(char)
          raw_tokens << _parse_string
        elsif NUMBERS.index(char)
          raw_tokens << _parse_number
        elsif char == "+"
          raw_tokens << _parse_plus
        elsif char == "-"
          raw_tokens << _parse_minus
        elsif char == "*"
          raw_tokens << _parse_star
        elsif char == "/"
          raw_tokens << _parse_slash
        elsif char == "&"
          raw_tokens << _parse_and
        elsif char == "|"
          raw_tokens << _parse_or
        elsif char == "!"
          raw_tokens << _parse_not
        elsif char == "="
          raw_tokens << _parse_equal
        elsif char == "<"
          raw_tokens << _parse_less_than
        elsif char == ">"
          raw_tokens << _parse_greater_than
        elsif "&|".index(char)
          raw_tokens << _parse_logical
        elsif char == "."
          raw_tokens << _parse_dot
        else
          raw_tokens << _parse_punctuation
        end
      end
      
      _set_line_numbers raw_tokens
      
      raw_tokens.map{|x|Token.new(x[:row], x[:col], source, x[:type], x[:text])}
    end
  end
end
