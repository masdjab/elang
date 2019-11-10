require './compiler/tokenizer'

cx = "  text = 'Hello \\'world\\'...'\r\n  puts text15\r\n  a = 0x3f + 0.2815 + 0.to_s\r\n"
puts (0...cx.length).map{|x|x % 10}.join
puts cx.gsub("\r", '*').gsub("\n", '*')
puts

tokenizer = Elang::Tokenizer.new
tokens = tokenizer.parse(cx)
tokens.each{|x|puts "#{x.row}, #{x.col}, #{x.type.inspect}, #{x.text.inspect}"}
