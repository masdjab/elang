require './compiler/parser_state_machine'

tt = 
  [
    '32135', '00000', '000001', '000323432635', 
    '.0234', '0.268', '758.0', '58.821', 
    '0x0', '0x00', '0x001', '0x1234', '0xabcd', '0x01df', 
    '_', '_12', '_aa', '___', '_abcdae123', 'as324', 'asdfwer', 
    'personName', 'personAge', 'personBirth1', 'MarritalStatus', 'x', 
    '11abc', '0x', '0000x21'
  ]

sm = ParserStateMachine.new
tt.each do |tx|
  sx = sm.parse(tx)
  puts sx.inspect
end

#sx = sm.parse("11abc(x*2,y)")
#puts sx.inspect
