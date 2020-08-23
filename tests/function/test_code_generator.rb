require_relative '../../compiler/cpu/intel16'
require_relative '../../compiler/code_generator'

module Elang
  symbols = Symbols.new
  cpu_model = CpuModel::Intel16.new
  cg = CodeGenerator.new(symbols, cpu_model)
  nodes = 
    [
      
    ]
end
