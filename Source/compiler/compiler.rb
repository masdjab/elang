# elang linker

require './compiler/identifier'
require './compiler/scope'
require './compiler/token'
require './compiler/symbol_request'
require './compiler/converter'
require './compiler/app_section'
require './compiler/app_image'
require './compiler/object_file'
require './compiler/parser'


src_file = ARGV[0]
parser = Assembly::Parser.new
parser.load_lib "compiler/stdlib.bin"
result = parser.parse File.read(src_file)
puts
puts result[:list]
#Assembly::ObjectFile::ObjectFile.new.write "output.bin", result
#result[:object].save "output.bin"

image = parser.libraries.map{|x|x.generate_code}.join + result[:object].image
file = File.new("output.bin", "wb")
file.write image
file.close
