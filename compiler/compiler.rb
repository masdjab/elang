require_relative 'exception'
require_relative 'file_info'
require_relative 'source_code'
require_relative 'parser'
require_relative 'lexer'
require_relative 'codeset_base'
require_relative 'codeset_binary'
require_relative 'base_language'
require_relative 'assembly_instruction'
require_relative 'machine_language'
require_relative 'scope'
require_relative 'scope_stack'
require_relative 'code_generator'
require_relative 'symbols'
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
    
    HELP_HINT = "Use -h or /? to view help."
    
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
    def generate_output_file(symbols, nodes)
      linker = Elang::Linker.new
      linker.load_library get_lib_file("stdlib.bin")
      codeset = BinaryCodeSet.new
      codegen = Elang::CodeGenerator.new(MachineLanguage.new(symbols, codeset))
      success = false
      
      delete_output_file @output_file.full
      
      if codegen.generate_code(nodes)
        if !(binary = linker.link(symbols, codeset)).empty?
          write_output_file @output_file.full, binary
          success = true
        end
      end
      
      success
    end
    
    public
    def compile
      puts
      
      symbols = Symbols.new
      sources = 
        [
          FileSourceCode.new(get_lib_file("libs.elang")), 
          FileSourceCode.new(@source_file.full)
        ]
      success = false
      
      if nodes = generate_nodes(sources, symbols)
        collect_names symbols, nodes
        success = generate_output_file(symbols, nodes)
      end
      
      if success
        puts "Source path: #{@source_file.path}"
        puts "Source file: #{@source_file.name_ext}"
        puts "Output file: #{@output_file.name_ext}"
        puts "Output size: #{File.size(@output_file.full)} byte(s)"
      end
    end
    def self.get_file_path_name_ext(filename)
      path = File.dirname(filename)
      path = !path.empty? ? "#{path}/" : ""
      extn = File.extname(filename)
      name = File.basename(filename)
      name = name[0...extn.length]
      [path, name, extn]
    end
    def self.display_title
      puts "ELANG v#{Elang::VERSION} by Heryudi Praja"
    end
    def self.display_usage
      puts
      puts "Usage: ruby elang.rb source_file [options]"
      puts
      puts "Available options:"
      puts "-d    Enable dev mode"
      puts "-nn   Nodes output to show: none"
      puts "-nl   Nodes output to show: libs"
      puts "-nu   Nodes output to show: user"
      puts "-na   Nodes output to show: all"
      puts "-h    Show this help"
      puts "/?    Alias for -h"
    end
    def self.display_error(msg)
      puts msg
    end
    def self.get_show_nodes_params(args)
      nn = args.delete("-nn")
      nl = args.delete("-nl")
      nu = args.delete("-nu")
      na = args.delete("-na")
      mm = {"-nn" => :none, "-nl" => :libs, "-nu" => :user, "-na" => :all}
      [nn, nl, nu, na].select{|x|!x.nil?}.inject({}){|a,b|a[b] = mm[b]; a}
    end
    def self.compile
      args = ARGV
      
      self.display_title
      
      if (args = ARGV).count == 0
        self.display_usage
      else
        source_file = args.shift
        show_help = args.delete("-h"){args.delete("/?"){false}}
        dev_mode = args.delete("-d"){false}
        show_nodes = get_show_nodes_params(args)
        
        if !args.empty?
          self.display_error "Invalid options: #{args.join(", ")}.\r\n#{HELP_HINT}"
        elsif show_help
          self.display_usage
        elsif show_nodes.count > 1
          self.display_error "Invalid show_nodes options: #{show_nodes.keys.join(" ")}.\r\n#{HELP_HINT}"
        else
          options = {dev: dev_mode}
          options[:show_nodes] = show_nodes.values.first if !show_nodes.empty?
          self.new(source_file, options).compile
        end
      end
    end
  end
end
