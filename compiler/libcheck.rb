require './compiler/converter'
require './compiler/code'
require './compiler/kernel'

kernel = Elang::Kernel.load_library(ARGV[0])
kernel.functions.each{|f|puts "#{Elang::Converter.int2hex(f[1][:offset], :dword).upcase}  #{f[1][:name]}"}
puts "\r\nTotal #{kernel.functions.count} function(s)"
