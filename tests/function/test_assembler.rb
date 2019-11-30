require './assembler/parser'
require './assembler/translator/base'
require './assembler/translator/i386'

cmd = <<EOS
  # parsing test
  putarg 0x200
  # comment
  getarg 0
EOS

tx1 = Assembler::BaseTranslator.new
tx2 = Assembler::I386Translator.new
asm = Assembler::Parser.new(tx2)
cmd = asm.parse(cmd.gsub("\n", "\r\n"))
cmd.each do |cx|
  puts cx.bytes.map{|x|Elang::Utils::Converter.int_to_bhex(x)}.join
end

doscmd = cmd + [0xcd.chr + 0x20.chr]
File.write("test.com", doscmd.join)
