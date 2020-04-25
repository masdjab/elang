require '../compiler/code'
require '../compiler/converter'
require '../compiler/kernel'

kernel = Elang::Kernel.load_library('stdlib16.bin')
list = 
  kernel.functions.map do |k,v|
    "#{Elang::Converter.int2hex(v[:offset], :word, :le).upcase} #{v[:name]}"
  end
File.write("offset.txt", list.join("\r\n") + "\r\n")
list.each{|i|puts i}
puts
puts "Total #{list.count} procs"
