module Elang
  class Project
    attr_accessor :source_file, :platform, :architecture, :output_format, :options
    
    def initialize
      @source_file = nil
      @platform = nil
      @architecture = nil
      @output_format = nil
      @options = {}
    end
  end
  
  
  class BaseProjectBuilder
    private
    def initialize(project)
      @project = project
    end
    
    public
    def build_project
    end
  end
  
  
  class ExecutableProjectBuilder < BaseProjectBuilder
    private
    def initialize(project)
      @project = project
    end
    def get_lib_file(file_name)
      "#{Elang::BASE_DIR}/libs/#{file_name}"
    end
    def load_kernel_libraries(library_file)
      libfile = get_lib_file(library_file)
      kernel = Kernel.load_library(libfile)
      kernel.functions << SystemFunction.new("_send_to_object", 0)
      kernel
    end
    def create_build_config
      nil
    end
    
    public
    def build_project
      build_config = create_build_config
      compiler = Compiler.new(build_config, @project.source_file, @project.options)
      compiler.compile
    end
  end
  
  
  class MsdosComProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.elang_lib = "libs.elang"
      config.kernel = load_kernel_libraries("libmsdos.bin")
      config.symbols = Symbols.new
      config.symbol_refs = []
      config.codeset = {}
      config.language = Language::Intel16.new(config)
      config.code_origin = 0x100
      config.heap_size = 0x8000
      config.first_block_offs = 0
      config.reserved_var_count = Variable::RESERVED_VARIABLE_COUNT
      config.var_byte_size = 2
      config.var_size_code = :word
      config.reference_resolver = ReferenceResolver16.new(config.kernel, config.language)
      config.method_dispatcher = MethodDispatcher16.new
      config.output_formatter = ComFormatter.new
      config
    end
  end
  
  
  class MsdosExe16ProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.elang_lib = "libs.elang"
      config.kernel = load_kernel_libraries("libmsdos.bin")
      config.symbols = Symbols.new
      config.symbol_refs = []
      config.codeset = {}
      config.language = Language::Intel16.new(config)
      config.code_origin = 0
      config.heap_size = 0x8000
      config.first_block_offs = 0
      config.reserved_var_count = Variable::RESERVED_VARIABLE_COUNT
      config.var_byte_size = 2
      config.var_size_code = :word
      config.reference_resolver = ReferenceResolver16.new(config.kernel, config.language)
      config.method_dispatcher = MethodDispatcher16.new
      config.output_formatter = Exe16Formatter.new
      config
    end
  end
  
  
  class DummyMsdosProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.elang_lib = nil
      config.kernel = load_kernel_libraries("libnull.bin")
      config.symbols = Symbols.new
      config.symbol_refs = []
      config.codeset = {}
      config.language = Language::Intel16.new(config)
      config.code_origin = 0x100
      config.heap_size = 0x8000
      config.first_block_offs = 0
      config.reserved_var_count = Variable::RESERVED_VARIABLE_COUNT
      config.var_byte_size = 2
      config.var_size_code = :word
      config.reference_resolver = ReferenceResolver16.new(config.kernel, config.language)
      config.method_dispatcher = MethodDispatcher16.new
      config.output_formatter = ComFormatter.new
      config
    end
  end
  
  
  class DadosProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.elang_lib = "libs.elang"
      config.kernel = load_kernel_libraries("libdados.bin")
      config.symbols = Symbols.new
      config.symbol_refs = []
      config.codeset = {}
      config.language = Language::Intel32.new(config)
      config.code_origin = 0xE000
      config.heap_size = 0x8000
      config.first_block_offs = 0
      config.reserved_var_count = Variable::RESERVED_VARIABLE_COUNT
      config.var_byte_size = 4
      config.var_size_code = :dword
      config.reference_resolver = ReferenceResolver32.new(config.kernel, config.language)
      config.method_dispatcher = MethodDispatcher32.new
      config.output_formatter = DxFormatter.new
      config
    end
  end
  
  
  class MswinProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.elang_lib = "libs.elang"
      config.kernel = load_kernel_libraries("libmswin.bin")
      config.symbols = Symbols.new
      config.symbol_refs = []
      config.codeset = {}
      config.language = Language::Intel32.new(config)
      config.code_origin = 0
      config.heap_size = 0x8000
      config.first_block_offs = 0
      config.reserved_var_count = Variable::RESERVED_VARIABLE_COUNT
      config.var_byte_size = 4
      config.var_size_code = :dword
      config.reference_resolver = ReferenceResolver32.new(config.kernel, config.language)
      config.method_dispatcher = MethodDispatcher32.new
      config.output_formatter = MzFormatter.new
      config
    end
  end
  
  
  class ProjectBuilderFactory
    def create_project_builder(project)
      if project.platform == "test"
        DummyMsdosProjectBuilder.new(project)
      elsif (project.platform == "msdos") || project.platform.nil?
        if !project.architecture.nil? && (project.architecture != "16")
          raise RuntimeError.new("MSDOS platform only support 16-bit architecture.")
        elsif !project.output_format.nil?
          dcformat = "#{project.output_format}".downcase
          if dcformat == "com"
            MsdosComProjectBuilder.new(project)
          elsif (dcformat == "exe") || (dcformat == "exe16")
            MsdosExe16ProjectBuilder.new(project)
          else
            raise RuntimeError.new("MSDOS platform only support MZ file format.")
          end
        else
          MsdosExe16ProjectBuilder.new(project)
        end
      elsif project.platform == "mswin"
        if !project.architecture.nil? && (project.architecture != "32")
          raise RuntimeError.new("MSWIN platform only support 32-bit architecture.")
        elsif !project.output_format.nil? && !["mzpe", "mzpedll"].include?("#{project.output_format}".downcase)
          raise RuntimeError.new("MSWIN platform only support mzpe and mzpedll formats.")
        else
          MswinProjectBuilder.new(project)
        end
      elsif project.platform == "dados"
        if !project.architecture.nil? && (project.architecture != "32")
          raise RuntimeError.new("Currently, Dados platform only support 32-bit architecture.")
        elsif !project.output_format.nil?
          raise RuntimeError.new("Currently, Dados platform only support flat binary file format.")
        else
          DadosProjectBuilder.new(project)
        end
      else
        raise RuntimeError.new("Unsupported platform: #{project.platform}")
      end
    end
  end
end
