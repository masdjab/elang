require_relative 'fetcher'
require_relative 'analyzer'

e1 = <<EOS
  # here is an "example" of 'source' codes...
  
  if (a + tmp1.items[3 * c] == 21) && tmp2.valid?(c)
    tmp1.just_do_that!
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
EOS

e2 = "  a = 32 + \"abc''d\".func(a[2] * 5 + (8 / p.size)) * 5  # no matter what"
e3 = "  32 + \"abc'xx'd 21 + 5 * (32.test)\".func(a[2] * 5 + (8 / p.size)) * 5  # no matter what"

=begin
lx = Lexer::Fetcher.new(e3)
tokens = []
while wd = lx.fetch
  # puts "[#{wd.position.line}, #{wd.position.column}] => #{wd.type}: \"#{wd.value}\""
  tokens << wd
end
puts tokens.map{|x|x.value}.join(16.chr)
#(1..255).each{|x|puts "#{x} => #{x.chr}"}
=end

parser = Lexer::Parser.new(e1)
parser.parse
