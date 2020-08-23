require 'test-unit'
require './compiler/cpu/intel16'
require './compiler/cpu/intel32'

class TestCpuIntel < Test::Unit::TestCase
  def hex2bin(str)
    Elang::Converter.hex2bin str
  end
  def bin2int(str)
    Elang::Converter.bin2int str
  end
  def test_features16
    cpu = Elang::CpuModel::Intel16.new
    
    assert_equal 0, cpu.code_length
    
    cpu.load_immediate(0x1234)
    assert_equal hex2bin("B83412"), cpu.output[-3, 3]
    assert_equal 3, cpu.code_length
    
    cpu.push
    assert_equal hex2bin("50"), cpu.output[-1, 1]
    
    cpu.pop
    assert_equal hex2bin("58"), cpu.output[-1, 1]
    
    cpu.ret
    assert_equal hex2bin("C3"), cpu.output[-1, 1]
    
    cpu.ret 2
    assert_equal hex2bin("C20400"), cpu.output[-3, 3]
    
    ro = cpu.set_global_variable nil
    assert_equal hex2bin("A30000"), cpu.output[-3, 3]
    assert_true ro.is_a?(Elang::GlobalVariableRef)
    
    ro = cpu.get_global_variable nil
    assert_equal hex2bin("A10000"), cpu.output[-3, 3]
    assert_true ro.is_a?(Elang::GlobalVariableRef)
    
    ro = cpu.set_local_variable nil
    assert_equal hex2bin("894600"), cpu.output[-3, 3]
    assert_true ro.is_a?(Elang::LocalVariableRef)
    
    ro = cpu.get_local_variable nil
    assert_equal hex2bin("8B4600"), cpu.output[-3, 3]
    assert_true ro.is_a?(Elang::LocalVariableRef)
    
    ro = cpu.call_function nil
    assert_equal hex2bin("E80000"), cpu.output[-3, 3]
    assert_true ro.is_a?(Elang::FunctionRef)
    
    cpu.get_parameter 0
    assert_equal hex2bin("8B4604"), cpu.output[-3, 3]
    
    s1 = cpu.set_jump_source nil
    assert_equal hex2bin("E90000"), cpu.output[-3, 3]
    assert_true s1.is_a?(Integer)
    
    s2 = cpu.set_jump_source :zr
    assert_equal hex2bin("0F840000"), cpu.output[-4, 4]
    assert_true s2.is_a?(Integer)
    
    s3 = cpu.set_jump_source :nz
    assert_equal hex2bin("0F850000"), cpu.output[-4, 4]
    assert_true s3.is_a?(Integer)
    
    old_length = cpu.code_length
    s4 = cpu.set_jump_source :xx
    assert_equal old_length, cpu.code_length
    assert_true s4.nil?
    
    cpu.set_jump_target s1, s1 + 2
    assert_equal 0, bin2int(cpu.output[s1, 2])
    
    cpu.set_jump_target s2, s2 + 6
    assert_equal 4, bin2int(cpu.output[s2, 2])
    
    cpu.set_jump_target s3, s1 - 1
    assert_equal 11, 0x10000 - bin2int(cpu.output[s3, 2])
  end
  def test_features32
    cpu = Elang::CpuModel::Intel32.new
    
    assert_equal 0, cpu.code_length
    
    cpu.load_immediate(0x12345678)
    assert_equal hex2bin("B878563412"), cpu.output[-5, 5]
    assert_equal 5, cpu.code_length
    
    cpu.push
    assert_equal hex2bin("50"), cpu.output[-1, 1]
    
    cpu.pop
    assert_equal hex2bin("58"), cpu.output[-1, 1]
    
    cpu.ret
    assert_equal hex2bin("C3"), cpu.output[-1, 1]
    
    cpu.ret 2
    assert_equal hex2bin("C20800"), cpu.output[-3, 3]
    
    ro = cpu.set_global_variable nil
    assert_equal hex2bin("A300000000"), cpu.output[-5, 5]
    assert_true ro.is_a?(Elang::GlobalVariableRef)
    
    ro = cpu.get_global_variable nil
    assert_equal hex2bin("A100000000"), cpu.output[-5, 5]
    assert_true ro.is_a?(Elang::GlobalVariableRef)
    
    ro = cpu.set_local_variable nil
    assert_equal hex2bin("894500"), cpu.output[-3, 3]
    assert_true ro.is_a?(Elang::LocalVariableRef)
    
    ro = cpu.get_local_variable nil
    assert_equal hex2bin("8B4500"), cpu.output[-3, 3]
    assert_true ro.is_a?(Elang::LocalVariableRef)
    
    ro = cpu.call_function nil
    assert_equal hex2bin("E800000000"), cpu.output[-5, 5]
    assert_true ro.is_a?(Elang::FunctionRef)
    
    cpu.get_parameter 0
    assert_equal hex2bin("8B4508"), cpu.output[-3, 3]
    
    s1 = cpu.set_jump_source nil
    assert_equal hex2bin("E900000000"), cpu.output[-5, 5]
    assert_true s1.is_a?(Integer)
    
    s2 = cpu.set_jump_source :zr
    assert_equal hex2bin("0F8400000000"), cpu.output[-6, 6]
    assert_true s2.is_a?(Integer)
    
    s3 = cpu.set_jump_source :nz
    assert_equal hex2bin("0F8500000000"), cpu.output[-6, 6]
    assert_true s3.is_a?(Integer)
    
    old_length = cpu.code_length
    s4 = cpu.set_jump_source :xx
    assert_equal old_length, cpu.code_length
    assert_true s4.nil?
    
    cpu.set_jump_target s1, s1 + 4
    assert_equal 0, bin2int(cpu.output[s1, 4])
    
    cpu.set_jump_target s2, s2 + 10
    assert_equal 6, bin2int(cpu.output[s2, 4])
    
    cpu.set_jump_target s3, s1 - 1
    assert_equal 17, 0x100000000 - bin2int(cpu.output[s3, 4])
  end
end
