# resources:
# https://docs.microsoft.com/en-us/windows/win32/debug/pe-format
# https://blog.kowalczyk.info/articles/pefileformat.html
# https://docs.microsoft.com/en-us/windows/win32/debug/pe-format
# https://en.wikipedia.org/wiki/DOS_MZ_executable
# https://web.archive.org/web/20120915093039/http://msdn.microsoft.com/en-us/magazine/cc301808.aspx
# https://docs.microsoft.com/en-us/archive/msdn-magazine/2002/february/inside-windows-win32-portable-executable-file-format-in-detail

# @3c => offset to PE signature
# location after PE signature:
# 00  4   signature                     PE\0\0
# 04  2   machine                       target machine identifier (0x14c = Intel 386 or later)
# 06  2   number of sections            indicates the size of section table which immediately follows the header
# 08  4   datetimestamp                 The low 32 bits of the number of seconds since 00:00 January 1, 1970 
#                                       (a C run-time time_t value), that indicates when the file was created.
# 0C  4   pointer to symbol table       the file offset of the COFF symbol table, or zero if not present
# 10  4   number of symbols             the number of entries in the symbol table
# 14  2   size of optional header   
# 16  2   characteristics               indicates the attributes of file
#                                       0x0100  Machine is based on a 32-bit-word architecture.
#                                       0x0008  COFF symbol table entries for local symbols have been removed.
#                                               This flag is deprecated and should be zero
#                                       0x0004  COFF line numbers have been removed.
#                                               This flag is deprecated and should be zero.
#                                       0x0002  This indicates that the image file is valid and can be run.
#                                               If this flag is not set, it indicates a linker error.
#                                       0x0001  Windows CE, and Microsoft Windows NT and later.

# optional header (pe32/pe32+):
# 00  18  2   magic number              0x10b   PE32
#                                       0x20b   PE32+
# 02  1a  1   major linker version
# 03  1b  1   minor linker version
# 04  1c  4   size of code
# 08  20  4   size of initialized data
# 0c  24  4   size of uninitialized data
# 10  28  4   address of entry point    entrypoint address
# 14  2c  4   base of code              address of beginning-of-code section relative to image base when loaded to memory
# for PE32
# 18  30  4   base of data              address of beginning-of-data section relative to image base when loaded to memory
# 1C  34  4   image base                preferred address of the first byte of image when loaded to memary
# 20  38  4   section alignment         
# 24  3c  4   file alignment
# 28  40  2   major os version
# 2a  42  2   minor os version
# 2c  44  2   major image version
# 2e  46  2   minor image version
# 30  48  2   major subsystem version
# 32  4a  2   minor subsystem version
# 34  4c  4   win32 version value       reserved, must be zero
# 38  50  4   size of image             the size in bytes of the image including all headers
# 3c  54  4   size of headers           total size of msdos stub, pe header, sections header rounded up to filealignment
# 40  58  4   checksum
# 44  5c  2   subsystem                 2   The Windows graphical user interface (GUI) subsystem
#                                       3   The Windows character subsystem
# 46  5e  2   DLL characteristics
# 48  60  4   size of stack reserve
# 4c  64  4   size of stack commit
# 50  68  4   size of heap reserve
# 54  6c  4   size of heap commit
# 58  70  4   loader flags              reserved must be zero
# 5c  74  4   number of rvas and sizes
# 60  78  8   export table              address and size of export table
# 68  80  8   import table              address and size of import table
# 70  88  8   resource table
# 78  90  8   exception table
# 80  98  8   certificate table
# 88  a0  8   base relocation table
# 90  a8  8   debug
# 98  b0  8   architecture
# a0  b8  8   global pointer
# a8  c0  8   TLS table
# b0  c8  8   load config table
# b8  d0  8   bound import
# c0  d8  8   IAT
# c8  e0  8   delay import descriptor
# d0  e8  8   CLR runtime header
# d8  f0  8   reserved, must be zero

# optional header data directories
# 00  4   virtual address
# 04  4   size


module Elang
  class MsdosStub
    DEFAULT_STUB_MESSAGE = "This program cannot be run in DOS mode.\r\n$"
    
    def initialize(mz_header_size, stub_message = DEFAULT_STUB_MESSAGE)
      @mz_header_size = mz_header_size
      @stub_message = stub_message
    end
    def to_bin
      zero_pads = 0.chr * (0x40 - @mz_header_size)
      zero_pads[0x3e - @mz_header_size, 2] = Converter.int2bin(0x80, :word)
      stub_cmd = Converter.hex2bin("0E1FBA0E00B409CD21B8014CCD21") + (@stub_message ? @stub_message : "")
      Code.align(zero_pads + stub_cmd, 16)
    end
  end
  
  
  class PeVersion
    attr_accessor :major, :minor, :name
    def initialize(major = nil, minor = nil, name = nil)
      @major = major
      @minor = minor
      @name = name
    end
    def to_bin(format = :word)
      [@major, @minor].map{|x|Converter.int2bin(x ? x : 0, format)}.join
    end
  end
  
  
  class PeRva
    attr_accessor :address, :size, :name
    def initialize(address = nil, size = nil, name = nil)
      @address = address
      @size = size
      @name = name
    end
    def to_bin
      [@address, @size].map{|x|Converter.int2bin(x ? x : 0, :dword)}.join
    end
  end
  
  
  class PeSection
    SECTION_CODE                = 0x00000020
    SECTION_INITIALIZED_DATA    = 0x00000040
    SECTION_UNINITIALIZED_DATA  = 0x00000080
    SECTION_MEMORY_SHARED       = 0x10000000
    SECTION_MEMORY_EXECUTE      = 0x20000000
    SECTION_MEMORY_READABLE     = 0x40000000
    SECTION_MEMORY_WRITABLE     = 0x80000000
    
    attr_accessor \
      :name, :virtual_size, :virtual_address, :size_of_raw_data, :pointer_to_raw_data, 
      :pointer_to_relocations, :pointer_to_line_numbers, :number_of_relocations, 
      :number_of_line_numbers, :section_flag
    
    def initialize
      @name = ""
      @virtual_size = 0
      @virtual_address = 0
      @size_of_raw_data = 0
      @pointer_to_raw_data = 0
      @pointer_to_relocations = 0
      @pointer_to_line_numbers = 0
      @number_of_relocations = 0
      @number_of_line_numbers = 0
      @section_flag = 0
    end
    def to_bin
      temp = 
        [
          (@name ? @name[0..7] : "").ljust(8, 0.chr), 
          Converter.int2bin(@virtual_size, :dword), 
          Converter.int2bin(@virtual_address, :dword), 
          Converter.int2bin(@size_of_raw_data, :dword), 
          Converter.int2bin(@pointer_to_raw_data, :dword), 
          Converter.int2bin(@pointer_to_relocations, :dword), 
          Converter.int2bin(@pointer_to_line_numbers, :dword), 
          Converter.int2bin(@number_of_relocations, :word), 
          Converter.int2bin(@number_of_line_numbers, :word), 
          Converter.int2bin(@section_flag, :dword)
        ]
      
      temp.join
    end
  end
  
  
  class PeHeader
    MAGIC_NUMBER_PE32         = 0x10b
    MACHINE_TYPE_I386         = 0x14c
    SUBSYSTEM_GUI             = 2
    SUBSYSTEM_CUI             = 3
    CHARACTERISTICS_DEFAULT   = 0x10f
    
    attr_accessor \
      :mz_header, :msdos_stub, :signature, :machine, :number_of_sections, :timestamp, :pointer_to_symbol_table, 
      :number_of_symbols, :size_of_optional_header, :characteristics, :magic_number, :linker_version, 
      :size_of_code, :size_of_initialized_data, :size_of_uninitialized_data, :entry_point, :base_of_code, 
      :base_of_data, :image_base, :section_alignment, :file_alignment, :os_version, :image_version, 
      :subsystem_version, :win32_version_value, :size_of_image, :size_of_headers, :checksum, :subsystem, 
      :dll_characteristics, :size_of_stack_reserve, :size_of_stack_commit, :size_of_heap_reserve, 
      :size_of_heap_commit, :loader_flags, :list_of_rvas, :sections
    
    private
    def initialize
      @mz_header = nil
      @msdos_stub = nil
      @signature = nil
      @machine = nil
      @number_of_sections = nil
      @timestamp = nil
      @pointer_to_symbol_table = nil
      @number_of_symbols = nil
      @size_of_optional_header = nil
      @characteristics = nil
      @magic_number = nil
      @linker_version = nil
      @size_of_code = nil
      @size_of_initialized_data = nil
      @size_of_uninitialized_data = nil
      @entry_point = nil
      @base_of_code = nil
      @base_of_data = nil
      @image_base = nil
      @section_alignment = nil
      @file_alignment = nil
      @os_version = nil
      @image_version = nil
      @subsystem_version = nil
      @win32_version_value = nil
      @size_of_image = nil
      @size_of_headers = nil
      @checksum = nil
      @subsystem = nil
      @dll_characteristics = nil
      @size_of_stack_reserve = nil
      @size_of_stack_commit = nil
      @size_of_heap_reserve = nil
      @size_of_heap_commit = nil
      @loader_flags = nil
      @list_of_rvas = []
      @sections = []
    end
    def timestamp_to_int(value)
      if value
        (value - Time.new(1970, 1, 1)).to_i
      else
        0
      end
    end
    
    public
    def self.create_rvas_template
      [
        PeRva.new(0, 0, :export), 
        PeRva.new(0, 0, :import), 
        PeRva.new(0, 0, :resource), 
        PeRva.new(0, 0, :exception), 
        PeRva.new(0, 0, :certificate), 
        PeRva.new(0, 0, :relocation), 
        PeRva.new(0, 0, :debug), 
        PeRva.new(0, 0, :architecture), 
        PeRva.new(0, 0, :pointer), 
        PeRva.new(0, 0, :tls), 
        PeRva.new(0, 0, :load_config), 
        PeRva.new(0, 0, :bound_import), 
        PeRva.new(0, 0, :iat), 
        PeRva.new(0, 0, :delay_import_descriptor), 
        PeRva.new(0, 0, :clr_runtime_header), 
        PeRva.new(0, 0, :reserved)
      ]
    end
    def to_bin
      @mz_header.extra_bytes = 0x80
      @mz_header.num_of_pages = 1
      
      temp = 
        [
          Code.align(@mz_header.to_bin + (@msdos_stub ? @msdos_stub.to_bin : ""), 0x80), 
          @signature, 
          Converter.int2bin(@machine, :word), 
          Converter.int2bin(@number_of_sections, :word), 
          Converter.int2bin(timestamp_to_int(@timestamp), :dword), 
          Converter.int2bin(@pointer_to_symbol_table, :dword), 
          Converter.int2bin(@number_of_symbols, :dword), 
          Converter.int2bin(@size_of_optional_header, :word), 
          Converter.int2bin(@characteristics, :word), 
          Converter.int2bin(@magic_number, :word), 
          @linker_version.to_bin(:byte), 
          Converter.int2bin(@size_of_code, :dword), 
          Converter.int2bin(@size_of_initialized_data, :dword), 
          Converter.int2bin(@size_of_uninitialized_data, :dword), 
          Converter.int2bin(@entry_point, :dword), 
          Converter.int2bin(@base_of_code, :dword), 
          Converter.int2bin(@base_of_data, :dword), 
          Converter.int2bin(@image_base, :dword), 
          Converter.int2bin(@section_alignment, :dword), 
          Converter.int2bin(@file_alignment, :dword), 
          @os_version.to_bin(:word), 
          @image_version.to_bin(:word), 
          @subsystem_version.to_bin(:word), 
          Converter.int2bin(@win32_version_value, :dword), 
          Converter.int2bin(@size_of_image, :dword), 
          Converter.int2bin(@size_of_headers, :dword), 
          Converter.int2bin(@checksum, :dword), 
          Converter.int2bin(@subsystem, :word), 
          Converter.int2bin(@dll_characteristics, :word), 
          Converter.int2bin(@size_of_stack_reserve, :dword), 
          Converter.int2bin(@size_of_stack_commit, :dword), 
          Converter.int2bin(@size_of_heap_reserve, :dword), 
          Converter.int2bin(@size_of_heap_commit, :dword), 
          Converter.int2bin(@loader_flags, :dword), 
          Converter.int2bin(@list_of_rvas.count, :dword), 
          @list_of_rvas.map{|x|x.to_bin}.join, 
          @sections.map{|x|x.to_bin}.join, 
        ]
      
      temp.join
    end
  end
end
