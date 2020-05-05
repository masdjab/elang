require_relative 'code'
require_relative 'exception'
require_relative 'file_info'
require_relative 'source_code'
require_relative 'kernel'
require_relative 'parser'
require_relative 'lexer'
require_relative 'assembly/instruction'
require_relative 'codeset'
require_relative 'scope'
require_relative 'scope_stack'
require_relative 'converter'
require_relative 'name_detector'
require_relative 'lex'
require_relative 'shunting_yard'
require_relative 'symbol/_load'
require_relative 'language/_load'
require_relative 'code_generator/_load'
require_relative 'symbol/_load'
require_relative 'code'
require_relative 'kernel'
require_relative 'converter'
require_relative 'build_config'
require_relative 'reference_resolver_16'
require_relative 'reference_resolver_32'
require_relative 'method_dispatcher_16'
require_relative 'method_dispatcher_32'
require_relative 'assembly/instruction'
require_relative 'assembly/code_builder'
require_relative 'linker_options'
require_relative 'code_section'
require_relative 'mswin_setup_generator'
require_relative 'dados_setup_generator'
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
      @stdlib       = options.fetch(:stdlib, "stdlib16.bin")
      @elang_lib    = options[:no_elang_lib] ? nil : "libs.elang"
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
      libfile = get_lib_file(@stdlib)
      Kernel.load_library(libfile)
    end
    def display_nodes(source, nodes, mode)
      if source.is_a?(FileSourceCode)
        file_type = File.basename(source.file_name) == @elang_lib ? :libs : :user
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
      codeset = Codeset.new
      language = Language::Intel16.new(kernel, symbols, symbol_refs, codeset)
      codegen = Elang::CodeGenerator::Intel.new(symbols, language)
      
      linker_options = LinkerOptions.new
      linker_options.var_byte_size = 2
      linker_options.var_size_code = :word
      linker_options.setup_generator = MsWinSetupGenerator.new
      
      linker = Elang::Linker.new(linker_options)
      success = false
      
      delete_output_file @output_file.full
      
      if codegen.generate_code(nodes)
        if !(binary = linker.link(kernel, language, symbols, symbol_refs, codeset)).empty?
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
      
      sources = []
      sources << FileSourceCode.new(get_lib_file(@elang_lib)) if @elang_lib
      sources << FileSourceCode.new(@source_file.full)
      
      kernel = load_kernel_libraries
      
      if nodes = generate_nodes(sources, symbols)
        collect_names symbols, nodes
        success = generate_output_file(:intel16, kernel, symbols, symbol_refs, nodes)
      end
      
      success
    end
  end
end
