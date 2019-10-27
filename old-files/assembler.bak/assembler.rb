# elang assembler

require_relative 'parser'

src_file = ARGV[0]
parser = Elang::Assembler::Parser.new
parser.load_lib "stdlib.bin"
result = parser.parse File.read(src_file)
puts
puts result[:list]
#Elang::Assembler::ObjectFile::ObjectFile.new.write "output.bin", result
#result[:object].save "output.bin"

image = parser.libraries.map{|x|x.generate_code}.join + result[:object].image
file = File.new("output.bin", "wb")
file.write image
file.close
