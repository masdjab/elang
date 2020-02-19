ELANG_DIR = File.dirname(__FILE__)
old_dir = Dir.pwd

Dir.chdir File.dirname(__FILE__)
require './compiler/main'
Dir.chdir old_dir

source_file = ARGV[0]
source_name = File.basename(source_file)
source_ext  = File.extname(source_file)
output_file = source_name[0...-source_ext.length] + ".com"

puts "Elang v1.0"

Elang::Main.new.compile(source_file, output_file)

puts "Source path: #{File.dirname(source_file)}"
puts "Source file: #{source_name}"
puts "Output file: #{output_file}"
