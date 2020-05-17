module Elang
  class ReferenceResolver32
    attr_accessor \
      :function_names, :classes, :string_constants, :variable_offset, 
      :code_origin, :context_offsets
    
    private
    def initialize(kernel, language)
      @kernel = kernel
      @language = language
      @function_names = nil
      @classes = nil
      @string_constants = nil
      @variable_offset = 0
      @code_origin = 0
      @context_offsets = {}
    end
    def context_offset(context)
      @context_offsets.fetch(context.to_s, 0)
    end
    def symbol_offset(symbol, offset = 0)
      context_offset(symbol.context) + symbol.offset + offset
    end
    def resolve_offset(ref, offset = 0)
      ro = context_offset(ref.context)
      so = context_offset(ref.symbol.context)
      result = so - ro + offset
      result
    end
    def resolve_info(ref, rv)
      rx = ref
      sx = ref.symbol
      rt = rx.class.to_s.gsub("Elang::", "")
      st = sx.class.to_s.gsub("Elang::", "")
      rc = rx.respond_to?(:context) ? rx.context.name : "(none)"
      sc = sx.respond_to?(:context) ? sx.context.name : "(none)"
      "#{rc}:#{rt} to #{sc}:#{st} @#{rx.location.to_s(16)} => #{(rv & 0xffff).to_s(16)}"
    end
    
    
    public
    def resolve_references(context, code, refs, origin)
      if !code.empty?
        refs.each do |ref|
          begin
            if ref.context.name == context.name
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
                if ref.is_a?(FunctionRef)
                  resolve_value = resolve_offset(ref, symbol.offset - (ref.location + 4)) & 0xffffffff
                  code[ref.location, 4] = Converter.int2bin(resolve_value, :dword)
                elsif ref.is_a?(AbsCodeRef)
                  code[ref.location, 4] = Converter.int2bin(symbol_offset(symbol, @code_origin), :dword)
                else
                  raise "Invalid reference type #{ref.class} to a #{symbol.class}"
                end
              elsif symbol.is_a?(SystemFunction)
                resolve_value = resolve_offset(ref, symbol.offset - (ref.location + 4)) & 0xffffffff
                code[ref.location, 4] = Converter.int2bin(resolve_value, :dword)
              elsif symbol.is_a?(FunctionId)
                if (resolve_value = @function_names.index(symbol.name)).nil?
                  raise "Unknown method '#{symbol.name}'"
                else
                  code[ref.location, 4] = Converter.int2bin(resolve_value, :dword)
                end
              elsif symbol.is_a?(Class)
                # currently not supported
              elsif symbol.is_a?(Label)
                if ref.is_a?(AbsCodeRef)
                  resolve_value = symbol_offset(symbol, @code_origin)
                  code[ref.location, 4] = Converter.int2bin(resolve_value, :dword)
                elsif ref.is_a?(ShortCodeRef)
                  code[ref.location, 1] = Converter.int2bin(symbol.offset - (ref.location + 1), :byte)
                elsif ref.is_a?(NearCodeRef)
                  resolve_value = resolve_offset(ref, symbol.offset - (ref.location + 2)) & 0xffff
                  code[ref.location, 4] = Converter.int2bin(resolve_value, :dword)
                elsif ref.is_a?(FarCodeRef)
                  code[ref.location, 6] = Converter.int2bin(symbol.offset - (ref.location + 6), :dword)
                else
                  raise "Cannot resolve reference of type '#{ref.class}' to label '#{symbol.name}'."
                end
              else
                raise "Cannot resolve reference to symbol of type '#{symbol.class}' => #{ref.inspect}"
              end
            end
          rescue Exception => e
            puts "Failed resolving reference, context: #{context.name}, ref: #{ref.inspect}"
            puts
            raise e
          end
        end
      end
    end
  end
end
