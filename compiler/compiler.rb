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
require_relative 'reference_resolver/_load'
require_relative 'method_dispatcher/_load'
require_relative 'assembly/instruction'
require_relative 'assembly/code_builder'
require_relative 'linker_options'
require_relative 'code_section'
require_relative 'setup_generator/_load'
require_relative 'linker'
require_relative 'project'


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
    
    attr_accessor :stdlib, :elang_lib
    attr_reader   :source_file, :output_file, :dev_mode, :show_nodes
    
    def initialize(build_config, linker_options, source_file, options = {})
      # available options: 
      # - dev(true/false)
      # - show_nodes(none, libs, user, all)
      
      @build_config   = build_config
      @linker_options = linker_options
      @source_file    = FileInfo.new(source_file)
      @output_file    = @source_file.replace_ext("com")
      @dev_mode       = options.fetch(:dev, false)
      @show_nodes     = options.fetch(:show_nodes, :none)
      @stdlib         = nil
      @elang_lib      = nil
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
    def generate_output_file(nodes)
      #language = Language::Intel16.new(@build_config)
      #codegen = Elang::CodeGenerator::Intel.new(@build_config.symbols, language)
      codegen = Elang::CodeGenerator::Intel.new(@build_config.symbols, @build_config.language)
      linker = Elang::Linker.new(@linker_options)
      success = false
      
      delete_output_file @output_file.full
      
      if codegen.generate_code(nodes)
        if !(binary = linker.link(@build_config)).empty?
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
      symbols = @build_config.symbols
      
      sources = []
      sources << FileSourceCode.new(get_lib_file(@elang_lib)) if @elang_lib
      sources << FileSourceCode.new(@source_file.full)
      
      if nodes = generate_nodes(sources, symbols)
        collect_names symbols, nodes
        success = generate_output_file(nodes)
      end
      
      {
        :success      => success, 
        :source_file  => @source_file.full, 
        :output_file  => @output_file.full
      }
    end
  end
end
