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
  
  
  class MswinComProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.elang_lib = "libs.elang"
      config.kernel = load_kernel_libraries("libmsdos16.elb")
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
  
  
  class MsdosMz16ProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.elang_lib = "libs.elang"
      config.kernel = load_kernel_libraries("libmsdos16.elb")
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
      config.output_formatter = MzFormatter.new
      config
    end
  end
  
  
  class MsdosMz32ProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.elang_lib = "libs.elang"
      config.kernel = load_kernel_libraries("libmsdos32.elb")
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
  
  
  class MswinPe32ProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.elang_lib = "libs.elang"
      config.kernel = load_kernel_libraries("libmswin32.elb")
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
      config.output_formatter = PeFormatter.new
      config
    end
  end
  
  
  class DummyMsdosProjectBuilder < ExecutableProjectBuilder
    def create_build_config
      config = BuildConfig.new
      config.elang_lib = nil
      config.kernel = load_kernel_libraries("libnull.elb")
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
      config.kernel = load_kernel_libraries("libdados.elb")
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
  
  
  class ProjectBuilderFactory
    def create_project_builder(project)
      format = "#{project.output_format}".downcase
      
      if ["com", "com16"].include?(format)
        project.platform = "msdos"
        MswinComProjectBuilder.new(project)
      elsif ["mz", "mz16", ""].include?(format)
        project.platform = "mswin"
        MsdosMz16ProjectBuilder.new(project)
      elsif ["mz32"].include?(format)
        project.platform = "msdos"
        MsdosMz32ProjectBuilder.new(project)
      elsif ["pe", "pe32"].include?(format)
        project.platform = "mswin"
        MswinPe32ProjectBuilder.new(project)
      elsif ["dx", "dx32"].include?(format)
        project.platform = "dados"
        DadosProjectBuilder.new(project)
      else
        raise "Unsupported output format: '#{project.output_format}'. Try one of following: com16, mz16, mz32, pe32, dx32."
      end
    end
  end
end
