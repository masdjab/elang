require './compiler/tokenizer'

cx = "text = 'Hello \\'world\\'...'\r\nputs text\r\na = b + c\r\n"
puts (0...cx.length).map{|x|x % 10}.join
puts cx.gsub("\r", '*').gsub("\n", '*')
puts

tokenizer = Elang::Tokenizer.new
tokens = tokenizer.parse(cx)
tokens.each{|x|puts "#{x.row}, #{x.col}, #{x.text.inspect}"}
