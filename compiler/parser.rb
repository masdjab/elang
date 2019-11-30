require './compiler/fetcher_v2'
require './compiler/token'

module Elang
  class Parser
    # syntax to be supported:
    # high priority:
    # - constant
    # - expression
    # - if condition then expression
    # - if block (with elsif, else and end)
    # - single assignment
    # - def function_name(arguments)
    # - end (function, class)
    # - class
    # medium priority:
    # - require
    # - import module_name
    # - from module_name import symbol1, symbol2, ...
    # low priority:
    # - expression if condition
    # - expression unless condition
    # - single/multi assignment
    
=begin
    attr_reader :libraries
    
    def initialize
      @current_line = ""
      @line_num = 0
      @char_pos = 0
      @identifiers = []
      @scope_stack = [nil]
      @symbol_requests = []
      @code_image = {libs: "", procs: "", main: ""}
      @code_description = ""
      #@object_file = ObjectFile::ObjectFile.new
      @libraries = []
      @application = Elang::EApplication.new("test")
    end
    def get_current_scope
      @scope_stack.last
    end
    def get_code_offset
      if (scope = get_current_scope).nil?
        @code_image[:main].length
      else
        @code_image[:procs].length
      end
    end
    def write_code(*bytes)
      #if (scope = get_current_scope).nil?
      #  @object_file.sections[:main].write Converter.bytes_to_str(*bytes)
      #else
      #  @object_file.sections[:procs].write Converter.bytes_to_str(*bytes)
      #end
    end
    def find_symbol(scope, name)
      @identifiers.find{|x|(x.scope == scope) && (x.name == name)}
    end
    def define_symbol(scope, name, type, value = nil)
      @identifiers << identifier = Identifier.new(scope, name, type, value)
      identifier
    end
    def define_and_get_symbol(scope, name, type, value = nil)
      if (identifier = find_symbol(scope, name)).nil?
        @identifiers << identifier = define_symbol(scope, name, type, value)
      end
      
      identifier
    end
    def find_str(text)
      @identifiers.find{|x|(x.type == :str) && (x.value == text)}
    end
    def define_str(text)
      #@object_file.sections[:text].write "#{Converter.int_to_word(text.length)}#{text}"
      #@identifiers << identifier = Identifier.new(nil, nil, :str, text)
      #identifier
    end
    def handle_loadstr(tokens)
      text = tokens[1][0].text
      text = !text.empty? ? text[1...-1] : ""
      
      if (identifier = find_str(text)).nil?
        identifier = define_str(text)
      end
      
      @symbol_requests << SymbolRequest.new(identifier, get_code_offset + 1, :data)
      write_code 0xB8, 0, 0
      @code_description << "B8[word strptr: #{text.inspect}]\n"
    end
    def handle_push(tokens)
      arg1 = tokens[1][0].text
      
      if arg1 == "acc"
        write_code 0x50
        @code_description << "50\n"
      elsif arg1 == "__app_context__"
        identifier = define_and_get_symbol(nil, "__app_context__", :method)
        @symbol_requests << SymbolRequest.new(identifier, get_code_offset + 1, :rel)
        write_code 0x68, 0, 0
        @code_description << "68[word offset: __app_context__]\n"
      else
        puts "Cannot handle push: #{tokens.inspect}"
      end
    end
    def handle_send(tokens)
      cmd = tokens[1][0].text
      identifier1 = define_and_get_symbol(nil, cmd, :method)
      identifier2 = define_and_get_symbol(nil, "send", :method)
      @symbol_requests << SymbolRequest.new(identifier1, get_code_offset + 1, :cmd)
      @symbol_requests << SymbolRequest.new(identifier2, get_code_offset + 4, :rel)
      write_code 0x68, 0, 0, 0xe8, 0, 0
      @code_description << "68[word command: #{cmd}]\ncall send\n"
    end
    def translate(tokens)
      case tokens[0].text
      when "loadstr"
        handle_loadstr tokens
      when "push"
        handle_push tokens
      when "send"
        handle_send tokens
      end
    end
    def convert_token_to_str_array(token)
      if token.is_a?(Array)
        token.map{|x|convert_token_to_str_array(x)}
      else
        token.text
      end
    end
    def dump_token(token)
      token_array = convert_token_to_str_array(token)
      cmd = token_array[0]
      arg = token_array.length > 1 ? token_array[1..-1] : nil
      arx = arg ? " #{arg.map{|x|x.join(" ")}.join(", ")}" : ""
      "#{cmd}#{arx}"
    end
    def load_lib(filename)
      @libraries << Elang::LibraryFileLoader.new.load(filename)
    end
    def parse(code)
      @line_num = 0
      
      code.each_line do |line|
        @line_num += 1
        line.chomp!("\n")
        stripped_line = line.strip
        
        if !stripped_line.empty? && !stripped_line.start_with?(";") && !stripped_line.start_with?("#")
          tokens = parse_line(line)
          puts dump_token(tokens)
          translate tokens
        end
      end
      
      write_code 0xcd, 0x20
      
      @application
    end
=end
    
    NUMBERS = "0123456789"
    LETTERS = "abcdefghijklmnopqrstuvwxyz"
    IDENTIFIER = "#{LETTERS}#{NUMBERS}_"
    
    def _raw_token(pos, type, text)
      {pos: pos, type: type, text: text}
    end
    def _parse_whitespace
      cpos = @fetcher.pos
      text = ""
      
      while char = @fetcher.char
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
      char = @fetcher.char
      text = ""
      
      if char == lnfd[0]
        text << @fetcher.fetch
        
        if @fetcher.char == lnfd[1]
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
      
      while char = @fetcher.char
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
      
      while char = @fetcher.char
        if IDENTIFIER.index(char.downcase)
          text << @fetcher.fetch
        else
          break
        end
      end
      
      _raw_token cpos, :identifier, text
    end
    def _parse_string
      text = ""
      cpos = @fetcher.pos
      quote = @fetcher.char
      
      while char = @fetcher.fetch
        if (char == quote) && !text.empty?
          text << char
          break
        else
          text << char
        end
      end
      
      _raw_token cpos, :string, text
    end
    def _parse_number
      text = ""
      cpos = @fetcher.pos
      
      while char = @fetcher.char
        if NUMBERS.index(char)
          text << @fetcher.fetch
        elsif char == "."
          if (text.length >= 2) && (text[0..1] == "0x")
            raise "Invalid char '#{char}' at #{@fetcher.pos}: #{@fetcher.text[cpos, 10]}..."
          elsif text.index(".").nil?
            num = nil
            
            if nc = @fetcher.next
              if NUMBERS.index(nc)
                text << @fetcher.fetch
              else
                break
              end
            else
              raise "Unexpected end of file at #{@fetcher.pos}: #{@fetcher.text[cpos, 10]}..."
            end
          end
        elsif char == "x"
          if text == "0"
            text << @fetcher.fetch
          else
            raise "Invalid char '#{char}' at #{@fetcher.pos}: #{@fetcher.text[cpos, 10]}..."
          end
        elsif "abcdef".index(char)
          if (text.length >= 2) && (text[0..1].downcase == "0x")
            text << @fetcher.fetch
          else
            raise "Invalid char '#{char}' at #{@fetcher.pos}: #{@fetcher.text[cpos, 10]}..."
          end
        elsif IDENTIFIER.index(char.downcase)
          raise "Invalid char '#{char}' at #{@fetcher.pos}: #{@fetcher.text[cpos, 10]}..."
        else
          break
        end
      end
      
      _raw_token cpos, :number, text
    end
    def _parse_equal
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :assign
      
      if @fetcher.char == "="
        text << @fetcher.fetch
        type = :equal
      end
      
      _raw_token cpos, type, text
    end
    def _parse_less_than
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :lt
      
      if @fetcher.char == "="
        text << @fetcher.fetch
        type = :le
      end
      
      _raw_token cpos, type, text
    end
    def _parse_greater_than
      cpos = @fetcher.pos
      text = @fetcher.fetch
      type = :gt
      
      if @fetcher.char == "="
        text << @fetcher.fetch
        type = :ge
      end
      
      _raw_token cpos, type, text
    end
    def _parse_logical
      cpos = @fetcher.pos
      tmap = {"&" => :and, "|" => :or}
      text = @fetcher.fetch
      
      if @fetcher.char == text
        text << @fetcher.fetch
      end
      
      _raw_token cpos, tmap[text[0]], text
    end
    def _detect_lines(code)
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
    def _set_line_numbers(tokens, lines)
      tokens.each do |token|
        line = lines.find{|x|(x[:min]..x[:max]).include?(token[:pos])}
        token.merge!(row: line[:row], col: token[:pos] - line[:min] + 1)
      end
    end
    def parse(code)
      @fetcher = FetcherV2.new(code)
      raw_tokens = []
      
      while char = @fetcher.char
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
        elsif char == "="
          raw_tokens << _parse_equal
        elsif char == "<"
          raw_tokens << _parse_less_than
        elsif char == ">"
          raw_tokens << _parse_greater_than
        elsif "&|".index(char)
          raw_tokens << _parse_logical
        else
          raw_tokens << _raw_token(@fetcher.pos, :punct, @fetcher.fetch)
        end
      end
      
      _set_line_numbers raw_tokens, _detect_lines(code)
      raw_tokens.map{|x|Token.new(x[:row], x[:col], x[:type], x[:text])}
    end
  end
end
