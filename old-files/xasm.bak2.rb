require './identifier'
require './scope'

module Assembly
  class Token
    attr_accessor :column, :text
    def initialize(column, text)
      @column = column
      @text = text
    end
  end
  
  class SymbolRequest
    attr_accessor :identifier, :location, :type
    def initialize(identifier, location, type)
      @identifier = identifier
      @location = location
      @type = type
    end
  end
  
  module ObjectFile
    class Section
      attr_reader   :name, :symbols
      attr_accessor :data
      
      def initialize(name)
        @name = name
        @data = ""
        @symbols = []
      end
      def length
        @data.length
      end
      def write(text)
        @data << text
      end
    end
    
    class ObjectFile
      def initialize
        @sections = 
          {
            :libs   => Section.new(:libs), 
            :procs  => Section.new(:procs), 
            :main   => Section.new(:main)
          }
      end
      def write(filename, sections)
        f = File.new(filename, "wb")
        f.write(sections[:image][:libs])
        f.write(sections[:image][:procs])
        f.write(sections[:image][:main])
        f.close
      end
    end
  end
  
  class Parser
    def initialize
      @current_line = ""
      @line_num = 0
      @char_pos = 0
      @identifiers = []
      @scope_stack = [nil]
      @symbol_requests = []
      @code_image = {libs: "", procs: "", main: ""}
      @code_description = ""
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
    def bytes_to_bin(*bytes)
      bytes.map{|x|x.chr}.join
    end
    def write_code(*bytes)
      binary_codes = bytes_to_bin(*bytes)
      
      if (scope = get_current_scope).nil?
        @code_image[:main] << binary_codes
      else
        @code_image[:procs] << binary_codes
      end
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
      @identifiers << identifier = Identifier.new(nil, nil, :str, text)
      identifier
    end
    def eol?
      !(0...@current_line.length).include?(@char_pos)
    end
    def fetch_while(&block)
      text = ""
      
      while !eol?
        chr = @current_line[@char_pos]
        if yield(chr, text)
          text += chr
          @char_pos += 1
        else
          break
        end
      end
      
      text
    end
    def fetch_string
      cp = @char_pos
      f_escape = false
      
      text = 
        fetch_while do |c,t|
          if c == "\""
            if !f_escape
              f_escape = false
              (t.length == 1) || (t[-1] != "\"")
            else
              f_escape = false
              true
            end
          elsif c == "\\"
            f_escape = true
            true
          else
            f_escape = false
            true
          end
        end
      
      Token.new(cp, text)
    end
    def fetch_number
      Token.new(@char_pos, fetch_while{|c,t|!"0123456789".index(c).nil?})
    end
    def fetch_word
      Token.new(@char_pos, fetch_while{|c,t|!":abcdefghijklmnopqrstuvwxyz_".index(c.downcase).nil?})
    end
    def fetch_symbol
      cp = @char_pos
      
      text = 
        fetch_while do |c,t|
          ((c == ":") && t.empty?) || !"abcdefghijklmnopqrstuvwxyz_".index(c.downcase).nil?
        end
      
      Token.new(cp, text)
    end
    def parse_line(line)
      @current_line = line
      @char_pos = 0
      
      tokens = []
      
      append_token = 
        lambda do |x|
          if tokens.empty?
            tokens << x
            tokens << []
          else
            tokens.last << x
          end
        end
      
      while !eol?
        chr = @current_line[@char_pos]
        
        if " \t".include?(chr)
          @char_pos += 1
        elsif ";#".index(chr)
          @char_pos = @current_line.length
        elsif chr == ","
          tokens << []
          @char_pos += 1
        elsif chr == "\""
          append_token.call fetch_string
        elsif "0123456789".index(chr)
          append_token.call fetch_number
        elsif ":abcdefghijklmnopqrstuvwxyz_".index(chr.downcase)
          append_token.call fetch_word
        elsif "+-*:".index(chr)
          append_token.call Token.new(@char_pos, chr)
          @char_pos += 1
        else
          raise "Unexpected '#{chr}' at line #{@line_num} col #{@char_pos + 1} in '#{line.inspect}'"
        end
      end
      
      tokens
    end
    def handle_loadstr(tokens)
      text = tokens[1][0].text
      
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
    def compile(code)
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
      
      {image: @code_image, description: @code_description}
    end
  end
end


src_file = ARGV[0]
result = Assembly::Parser.new.compile File.read(src_file)
puts
puts result[:description]
Assembly::ObjectFile::ObjectFile.new.write "output.bin", result
