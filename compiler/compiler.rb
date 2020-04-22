require_relative 'code'
require_relative 'exception'
require_relative 'file_info'
require_relative 'source_code'
require_relative 'kernel'
require_relative 'parser'
require_relative 'lexer'
require_relative 'assembly/instruction'
require_relative 'codeset'
require_relative 'language/_load'
require_relative 'scope'
require_relative 'scope_stack'
require_relative 'code_generator'
require_relative 'symbol/_load'
require_relative 'linker'


module Elang
  BASE_DIR  = File.dirname(File.dirname(__FILE__))
  VERSION   = "1.0"
  
  class Compiler
    # class responsibility: convert source code to executable binary codes
    # - convert source code to tokens
    # - convert tokens to lex nodes using lexer
    # - create codeset from lex nodes using code generator
    # - generate dev files as needed
    # - resolve symbol references
    # - build final binary code
    
    attr_reader :source_file, :output_file, :dev_mode, :show_nodes
    
    def initialize(source_file, options = {})
      # available options: 
      # - dev(true/false)
      # - show_nodes(none, libs, user, all)
      
      @source_file  = FileInfo.new(source_file)
      @output_file  = @source_file.replace_ext("com")
      @dev_mode     = options.fetch(:dev, false)
      @show_nodes   = options.fetch(:show_nodes, :none)
    end
    def get_lib_file(file_name)
      "#{BASE_DIR}/libs/#{file_name}"
    end
    def write_output_file(file_name, content)
      begin
        file = File.new(file_name, "wb")
        file.write content
        file.close
      rescue Exception => ex
        puts "Error writing to file '#{file_name}'."
      end
    end
    def delete_output_file(file_name)
      File.delete file_name if File.exist?(file_name)
    end
    def load_kernel_libraries
      libfile = get_lib_file("stdlib16.bin")
      Kernel.load_library(libfile)
    end
    def display_nodes(source, nodes, mode)
      if source.is_a?(FileSourceCode)
        file_type = File.basename(source.file_name) == "libs.elang" ? :libs : :user
      else
        file_type = :user
      end
      
      if [:all, file_type].include?(mode)
        puts Lexer.sexp_to_s(nodes)
        puts
      end
    end
    def generate_nodes(sources, symbols)
      parser = Elang::Parser.new
      lexer = Elang::Lexer.new
      success = true
      
      nodes = []
      sources.each do |source|
        tokens = parser.parse(source)
        
        if nn = lexer.to_sexp_array(tokens)
          display_nodes source, nn, @show_nodes
          nodes += nn
        else
          success = false
          break
        end
      end
      
      success ? nodes : nil
    end
    def collect_names(symbols, nodes)
      NameDetector.new(symbols).detect_names nodes
    end
    def generate_output_file(lang_code, kernel, symbols, symbol_refs, nodes)
      linker = Elang::Linker.new(kernel)
      codeset = Codeset.new
      language = Language::Intel16.new(kernel, symbols, symbol_refs, codeset)
      #language = Language::Intel32.new(kernel, symbols, symbol_refs, codeset)
      codegen = Elang::CodeGenerator.new(language)
      success = false
      
      delete_output_file @output_file.full
      
      if codegen.generate_code(nodes)
        if !(binary = linker.link(symbols, symbol_refs, codeset)).empty?
          write_output_file @output_file.full, binary
          success = true
        end
      end
      
      success
    end
    
    public
    def compile
      puts
      
      success = false
      symbols = Symbols.new
      symbol_refs = []
      sources = 
        [
          FileSourceCode.new(get_lib_file("libs.elang")), 
          FileSourceCode.new(@source_file.full)
        ]
      kernel = load_kernel_libraries
      
      if nodes = generate_nodes(sources, symbols)
        collect_names symbols, nodes
        success = generate_output_file(:intel16, kernel, symbols, symbol_refs, nodes)
      end
      
      success
    end
  end
end
