module Elang
  class ReferenceResolver32
    attr_accessor :function_names, :classes, :string_constants, :variable_offset, :dispatcher_offset
    
    def initialize(kernel, language)
      @kernel = kernel
      @language = language
      @function_names = nil
      @classes = nil
      @string_constants = nil
      @variable_offset = 0
      @dispatcher_offset = 0
    end
    def resolve_references(section_name, code, refs, origin)
      if !code.empty?
        refs.each do |ref|
          if ref.section_name == section_name
            symbol = ref.symbol
            
            if symbol.is_a?(Constant)
              resolve_value = @string_constants[symbol.name][:offset]
              code[ref.location, 4] = Converter.int2bin(resolve_value, :dword)
            elsif symbol.is_a?(FunctionParameter)
              arg_offset = symbol.scope.cls ? 3 : 0
              resolve_value = (arg_offset + symbol.index + 2) * 4
              code[ref.location, 1] = Converter.int2bin(resolve_value, :byte)
            elsif symbol.is_a?(Variable)
              if symbol.scope.root?
                resolve_value = @variable_offset + (symbol.index - 1) * 4
                code[ref.location, 4] = Converter.int2bin(resolve_value, :dword)
              else
                resolve_value = -symbol.index * 4
                code[ref.location, 1] = Converter.int2bin(resolve_value, :byte)
              end
            elsif symbol.is_a?(InstanceVariable)
              if (clsinfo = @classes[symbol.scope.cls]).nil?
                raise "Cannot find class '#{symbol.scope.cls}' in class info list"
              elsif (index = clsinfo[:i_vars].index(symbol.name)).nil?
                raise "Cannot find instance variable '#{symbol.name}' in '#{symbol.scope.cls}' class info"
              else
                code[ref.location, 4] = Converter.int2bin(index, :dword)
              end
            elsif symbol.is_a?(Function)
              resolve_value = symbol.offset - (origin + ref.location + 4)
              code[ref.location, 4] = Converter.int2bin(resolve_value, :dword)
            elsif symbol.is_a?(SystemFunction)
              if symbol.name == "_send_to_object"
                resolve_value = @dispatcher_offset - (origin + ref.location + 4)
                code[ref.location, 4] = Converter.int2bin(resolve_value, :dword)
              elsif sys_function = @kernel.functions[symbol.name]
                resolve_value = sys_function[:offset] - (origin + ref.location + 4)
                code[ref.location, 4] = Converter.int2bin(resolve_value, :dword)
              else
                raise "Undefined system function '#{symbol.name.inspect}'"
              end
            elsif symbol.is_a?(FunctionId)
              if (resolve_value = @function_names.index(symbol.name)).nil?
                raise "Unknown method '#{symbol.name}'"
              else
                code[ref.location, 4] = Converter.int2bin(resolve_value, :dword)
              end
            elsif symbol.is_a?(Class)
#puts "Resolving class '#{symbol.name}', index: #{symbol.index}"
            else
              raise "Cannot resolve reference to symbol of type '#{symbol.class}' => #{ref.inspect}"
            end
          end
        end
      end
    end
  end
end
