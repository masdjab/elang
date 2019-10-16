# elang linker

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
  
  class Converter
    def self.bytes_to_str(*bytes)
      bytes.map{|x|x.chr}.join
    end
    def self.int_to_word(value)
      hi = (value & 0xff00) >> 8
      lo = value & 0xff
      lo.chr + hi.chr
    end
    def self.word_to_int(value)
      bytes = value.bytes
      (1 << 8) * bytes[1] + bytes[0]
    end
    def self.dword_to_int(value)
      bytes = value.bytes
      (1 << 24) * bytes[3] + (1 << 16) * bytes[2] + (1 << 8) * bytes[1] + bytes[0]
    end
  end
  
  class AppSection
    CODE = 1
    TEXT = 2
    DATA = 3
    RELOCATION = 4
    IMPORT = 5
    EXPORT = 6
    APP_INFO = 7
    
    attr_accessor :name, :flag, :offset, :size, :body
    def initialize
      @name = name
      @flag = flag
      @offset = offset
      @size = size
      @body = body
    end
  end
  
  class AppImage
    attr_accessor \
      :signature, :file_size, :header_size, :section_table_offset, 
      :section_table_size, :main_entry_point, :checksum, :raw_image, 
      :sections, :symbol_hash
    
    def initialize
      @signature = ""
      @file_size = 0
      @header_size = 0
      @section_table_offset = 0
      @section_table_size = 0
      @main_entry_point = 0
      @checksum = 0
      @raw_image = ""
      @sections = {}
      @symbol_hash = {}
    end
    def self.load(filename)
      file = File.new(filename, "rb")
      content = file.read
      file.close
      
      library = self.new
      library.signature = content[0..2]
      library.file_size = Converter.dword_to_int(content[4..7])
      library.header_size = Converter.word_to_int(content[8..9])
      library.section_table_offset = Converter.word_to_int(content[12..13])
      library.section_table_size = Converter.word_to_int(content[14..15])
      library.main_entry_point = Converter.dword_to_int(content[16..19])
      library.checksum = Converter.dword_to_int(content[20..23])
      
      sect_table = content[library.section_table_offset, library.section_table_size]
      library.sections = 
        (0...(sect_table.length / 16)).map do |s|
          crt_sect = sect_table[16 * s, 16]
          section = AppSection.new
          zr_pos = crt_sect.index(0.chr)
          section.name = zr_pos ? crt_sect[0...zr_pos] : crt_sect[0..4]
          section.flag = crt_sect[4].bytes[0]
          section.offset = Converter.dword_to_int(crt_sect[8, 4])
          section.size = Converter.dword_to_int(crt_sect[12, 4])
          section.body = content[section.offset, section.size]
          section
        end
      
      code_sect = library.sections.find{|x|x.flag == AppSection::CODE}
      library.raw_image = code_sect ? code_sect.body : ""
      
      library
    end
    def format(formatter)
    end
    def save(filename, formatter)
      f = File.new(filename, "wb")
      f.write self.format(formatter)
      f.close
    end
    def generate_code(offset = 0)
      @raw_image
    end
  end
  
  module ObjectFile
    class Section
      attr_reader   :name, :symbols
      attr_accessor :data
      
      private
      def initialize(name)
        @name = name
        @data = ""
        @symbols = []
      end
      def length
        @data.length
      end
      
      public
      def write(text)
        @data << text
      end
    end
    
    class ObjectFile
      attr_reader :sections
      
      def initialize
        @sections = 
          {
            :libs   => Section.new(:libs), 
            :procs  => Section.new(:procs), 
            :main   => Section.new(:main), 
            :text   => Section.new(:text)
          }
      end
      def align(image)
        if ((length = image.length) % 16) == 0
          image
        else
          image + (0.chr * (16 - (length % 16)))
        end
      end
      def image
        [
          align(@sections[:libs].data), 
          align(@sections[:procs].data), 
          align(@sections[:main].data), 
          align(@sections[:text].data)
        ].join
      end
      def save(filename)
        f = File.new(filename, "wb")
        f.write image
        f.close
      end
    end
  end
  
  class Parser
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
      @object_file = ObjectFile::ObjectFile.new
      @libraries = []
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
      if (scope = get_current_scope).nil?
        @object_file.sections[:main].write Converter.bytes_to_str(*bytes)
      else
        @object_file.sections[:procs].write Converter.bytes_to_str(*bytes)
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
      @object_file.sections[:text].write "#{Converter.int_to_word(text.length)}#{text}"
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
      @libraries << AppImage.load(filename)
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
      
      # {image: @code_image, description: @code_description}
      {object: @object_file, list: @code_description}
    end
  end
end


src_file = ARGV[0]
parser = Assembly::Parser.new
parser.load_lib "stdlib.bin"
result = parser.parse File.read(src_file)
puts
puts result[:list]
#Assembly::ObjectFile::ObjectFile.new.write "output.bin", result
#result[:object].save "output.bin"

image = parser.libraries.map{|x|x.generate_code}.join + result[:object].image
file = File.new("output.bin", "wb")
file.write image
file.close
