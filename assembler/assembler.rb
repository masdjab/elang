# elang assembler

require './assembler/compiler'

src_file = ARGV[0]
compiler = Elang::Assembler::Compiler.new
compiler.import_lib "stdlib.bin"
compiled = compiler.compile File.read(src_file)
puts
puts compiled[:list]
#Elang::Assembler::ObjectFile::ObjectFile.new.write "output.bin", compiled
#compiled[:object].save "output.bin"

image = compiled[:object].image
file = File.new("output.bin", "wb")
file.write image
file.close
