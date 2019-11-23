require './assembler/assembler'
require './assembler/translator/base'

cmd = <<EOS
  # parsing test
  put 0x10002108
  put 0x20004238
  # comment
  get
  put 0x30005479
  is_eq
  and
  or
  xor
  jit 0x40002141
  nop
  jif -3
  nop
EOS

asm = Assembler::Assembler.new(Assembler::BaseTranslator.new)
cmd = asm.parse(cmd.gsub("\n", "\r\n"))
cmd.each do |cx|
  puts cx.bytes.map{|x|Elang::Utils::Converter.int_to_bhex(x)}.join
end

require './utils/converter'
puts "-3 => #{Elang::Utils::Converter.int_to_dword(-3).bytes.map{|x|Elang::Utils::Converter.int_to_bhex(x)}.join}"
