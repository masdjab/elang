require './compiler/main'

source_file = ARGV[0]
source_name = File.basename(source_file)
source_ext  = File.extname(source_file)
output_file = source_name[0...-source_ext.length] + ".com"

Elang::Main.new.compile(source_file, output_file)

puts "Elang v1.0"
puts "Source path: #{File.dirname(source_file)}"
puts "Source file: #{source_name}"
puts "Output file: #{output_file}"
