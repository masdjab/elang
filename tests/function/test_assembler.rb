require './assembler/assembler'
require './assembler/translator/base'
require './assembler/translator/i386'

cmd = <<EOS
  # parsing test
  put 0x200
  # comment
  get
EOS

tx1 = Assembler::BaseTranslator.new
tx2 = Assembler::I386Translator.new
asm = Assembler::Assembler.new(tx2)
cmd = asm.parse(cmd.gsub("\n", "\r\n"))
cmd.each do |cx|
  puts cx.bytes.map{|x|Elang::Utils::Converter.int_to_bhex(x)}.join
end

doscmd = cmd + [0xcd.chr + 0x20.chr]
File.write("test.com", doscmd.join)
