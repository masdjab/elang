ELANG_DIR = File.dirname(__FILE__)
old_dir = Dir.pwd

Dir.chdir File.dirname(__FILE__)
require './compiler/main'
Dir.chdir old_dir

ext_types   = {"assembly" => "asm", "intermediate" => "txt", "machine" => "com"}
source_file = ARGV[0]
language    = ARGV.count == 2 ? ARGV[1] : "machine"
source_path = File.dirname(source_file)
source_path = !source_path.empty? ? "#{source_path}/" : ""
source_name = File.basename(source_file)
source_ext  = File.extname(source_file)

puts "Elang v1.0"
puts

if !ext_types.key?(language)
  puts "Invalid language type: 'language'. Try #{ext_types.keys.join(", ")}."
else
  output_file = source_path + source_name[0...-source_ext.length] + ".#{ext_types[language]}"
  
  if Elang::Main.new.compile(source_file, output_file, language)
    puts "Source path: #{source_path.chomp("/").chomp("\\")}"
    puts "Source file: #{source_name}"
    puts "Output file: #{output_file}"
    puts "Output size: #{File.size(output_file)} byte(s)"
    puts "Output type: #{language}"
  end
end
