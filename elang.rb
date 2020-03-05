ELANG_DIR = File.dirname(__FILE__)
old_dir = Dir.pwd

Dir.chdir File.dirname(__FILE__)
require './compiler/main'
Dir.chdir old_dir

source_file = ARGV[0]
source_path = File.dirname(source_file)
source_path = !source_path.empty? ? "#{source_path}/" : ""
source_name = File.basename(source_file)
source_ext  = File.extname(source_file)
output_file = source_path + source_name[0...-source_ext.length] + ".com"
language    = ARGV.count == 2 ? ARGV[1] : "machine"

puts "Elang v1.0 - #{language.upcase}"
puts

if Elang::Main.new.compile(source_file, output_file, language)
  puts "Source path: #{source_path}"
  puts "Source file: #{source_name}"
  puts "Output file: #{output_file}"
  puts "Output size: #{File.size(output_file)} byte(s)"
end
