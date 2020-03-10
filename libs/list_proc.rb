require '../utils/converter'

cat_file = File.new("stdlib.bin", "rb")
content = cat_file.read
cat_file.close

procs = []
toc_size = Elang::Utils::Converter.word_to_int(content[0, 2])
read_pos = 2
eos_char = 0.chr
loop do
  begin
    if content[read_pos, 5] != "#EOL#"
      oo = Elang::Utils::Converter.word_to_int(content[read_pos + 0, 2]) + 0x110 - toc_size
      mp = content.index(eos_char, read_pos + 2)
      fn = content[(read_pos + 2)...mp]
      procs << {addr: oo, name: fn}
      read_pos = read_pos + 2 + fn.length + 1
    else
      break
    end
  rescue Exception => ex
    last_proc = !procs.empty? ? procs.last : nil
    last_name = last_proc ? last_proc[:name] : "(None)"
    puts "Last processed function names: #{procs[-5..-1].map{|x|x[:name]}.join(", ")}"
    puts "Total processed: #{procs.count}"
    raise ex
  end
end

list = procs.map{|x|"#{Elang::Utils::Converter.int_to_whex(x[:addr]).upcase} #{x[:name]}"}
File.write("offset.txt", list.join("\r\n") + "\r\n")
list.each{|i|puts i}
puts "Total #{procs.count} procs"
