module Elang
  class Project
    attr_accessor :platform, :architecture, :output_format, :source_file, :options
    
    def initialize
      @platform = nil
      @architecture = nil
      @output_format = nil
      @source_file = nil
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
      Kernel.load_library(libfile)
    end
    def create_build_config
      nil
    end
    def create_linker_options(build_config)
      nil
    end
    def create_compiler(build_config, linker_options)
      nil
    end
    
    public
    def build_project
      build_config = create_build_config
      linker_options = create_linker_options(build_config)
      compiler = create_compiler(build_config, linker_options)
      compiler.compile
    end
  end
  
  
  class MsdosProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.kernel = load_kernel_libraries("libmsdos.bin")
      config.symbols = Symbols.new
      config.symbol_refs = []
      config.codeset = Codeset.new
      config.language = Language::Intel16.new(config)
      config.code_origin = 0x100
      config.heap_size = 0x8000
      config.first_block_offs = 0
      config.reserved_var_count = Variable::RESERVED_VARIABLE_COUNT
      config
    end
    def create_linker_options(build_config)
      options = LinkerOptions.new
      options.var_byte_size = 2
      options.var_size_code = :word
      options.reference_resolver = ReferenceResolver16.new(build_config.kernel, build_config.language)
      options.method_dispatcher = MethodDispatcher16.new
      options.setup_generator = MsdosSetupGenerator.new
      options
    end
    def create_compiler(build_config, linker_options)
      compiler = Compiler.new(build_config, linker_options, @project.source_file, @project.options)
      compiler.stdlib = "libmsdos.bin"
      compiler.elang_lib = "libs.elang"
      compiler
    end
  end
  
  
  class DummyMsdosProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.kernel = load_kernel_libraries("libnull.bin")
      config.symbols = Symbols.new
      config.symbol_refs = []
      config.codeset = Codeset.new
      config.language = Language::Intel16.new(config)
      config.code_origin = 0x100
      config.heap_size = 0x8000
      config.first_block_offs = 0
      config.reserved_var_count = Variable::RESERVED_VARIABLE_COUNT
      config
    end
    def create_linker_options(build_config)
      options = LinkerOptions.new
      options.var_byte_size = 2
      options.var_size_code = :word
      options.reference_resolver = ReferenceResolver16.new(build_config.kernel, build_config.language)
      options.method_dispatcher = MethodDispatcher16.new
      options.setup_generator = MsdosSetupGenerator.new
      options
    end
    def create_compiler(build_config, linker_options)
      compiler = Compiler.new(build_config, linker_options, @project.source_file, @project.options)
      compiler.stdlib = nil
      compiler.elang_lib = nil
      compiler
    end
  end
  
  
  class DadosProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.kernel = load_kernel_libraries("libdados.bin")
      config.symbols = Symbols.new
      config.symbol_refs = []
      config.codeset = Codeset.new
      config.language = Language::Intel32.new(config)
      config.code_origin = 0
      config.heap_size = 0x8000
      config.first_block_offs = 0
      config.reserved_var_count = Variable::RESERVED_VARIABLE_COUNT
      config
    end
    def create_linker_options(build_config)
      options = LinkerOptions.new
      options.var_byte_size = 4
      options.var_size_code = :dword
      options.reference_resolver = ReferenceResolver32.new(build_config.kernel, build_config.language)
      options.method_dispatcher = MethodDispatcher32.new
      options.setup_generator = DadosSetupGenerator.new
      options
    end
    def create_compiler(build_config, linker_options)
      compiler = Compiler.new(build_config, linker_options, @project.source_file, @project.options)
      compiler.stdlib = "libdados.bin"
      compiler.elang_lib = "libs.elang"
      compiler
    end
  end
  
  
  class MswinProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.kernel = load_kernel_libraries("libmswin.bin")
      config.symbols = Symbols.new
      config.symbol_refs = []
      config.codeset = Codeset.new
      config.language = Language::Intel32.new(config)
      config.code_origin = 0
      config.heap_size = 0x8000
      config.first_block_offs = 0
      config.reserved_var_count = Variable::RESERVED_VARIABLE_COUNT
      config
    end
    def create_linker_options(build_config)
      options = LinkerOptions.new
      options.var_byte_size = 4
      options.var_size_code = :dword
      options.reference_resolver = ReferenceResolver32.new(build_config.kernel, build_config.language)
      options.method_dispatcher = MethodDispatcher32.new
      options.setup_generator = DadosSetupGenerator.new
      options
    end
    def create_compiler(build_config, linker_options)
      compiler = Compiler.new(build_config, linker_options, @project.source_file, @project.options)
      compiler.stdlib = "libmswin.bin"
      compiler.elang_lib = "libs.elang"
      compiler
    end
  end
  
  
  class ProjectBuilderFactory
    def create_project_builder(project)
      if project.platform == "test"
        DummyMsdosProjectBuilder.new(project)
      elsif (project.platform == "msdos") || project.platform.nil?
        if !project.architecture.nil? && (project.architecture != "16")
          raise RuntimeError.new("MSDOS platform only support 16-bit architecture.")
        elsif !project.output_format.nil? && ("#{project.output_format}".downcase != "mz")
          raise RuntimeError.new("MSDOS platform only support MZ file format.")
        else
          MsdosProjectBuilder.new(project)
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
