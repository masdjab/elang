class Token
  attr_accessor :column, :text
  def initialize(column, text)
    @column = column
    @text = text
  end
end

class Assembler
  def initialize
    @current_line = ""
    @char_pos = 0
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
    
    while !eol?
      chr = @current_line[@char_pos]
      
      if " \t".include?(chr)
        @char_pos += 1
      elsif ";#".index(chr)
        @char_pos = @current_line.length
      elsif chr == ","
        tokens << Token.new(@char_pos, ",")
        @char_pos += 1
      elsif chr == "\""
        tokens << fetch_string
      elsif "0123456789".index(chr)
        tokens << fetch_number
      elsif ":abcdefghijklmnopqrstuvwxyz_".index(chr.downcase)
        tokens << fetch_word
      elsif "+-*:".index(chr)
        tokens << Token.new(@char_pos, chr)
        @char_pos += 1
      else
        raise "Unexpected '#{chr}' at col #{@char_pos + 1} in '#{line.inspect}'"
      end
    end
    
    tokens
  end
  def translate(tokens)
  end
  def compile(code)
    code.each_line do |line|
      line.chomp!("\n")
      stripped_line = line.strip
      
      if !stripped_line.empty? && !stripped_line.start_with?(";") && !stripped_line.start_with?("#")
        tokens = parse_line(line)
        cmd = tokens.first.text
        arg = tokens.length > 1 ? " #{tokens[1..-1].map{|x|x.text}.join(" ")}" : ""
        puts "#{cmd}#{arg}"
        translate tokens
      end
    end
  end
end


src_file = ARGV[0]
Assembler.new.compile File.read(src_file)
