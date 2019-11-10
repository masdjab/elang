require './assembler/assembler'
require './assembler/translator/base'

cmd = <<EOS
  # parsing test
  put 21059
  put 21805
  # comment
  get
  put 93744
  is_eq
EOS

asm = Assembler::Assembler.new(Assembler::BaseTranslator.new)
asm.parse(cmd.gsub("\n", "\r\n"))
