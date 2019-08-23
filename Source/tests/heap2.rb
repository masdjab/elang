# code sample

BLK_FREE = 0
BLK_USED = 1
BLK_FIRST = 2
BLK_LAST = 4

ERR_OUT_OF_MEMORY = "Out of memory"

  '''
  another type of comments
  '''
  
  """
  comments too
  """
  
WelcomeMessage = <<EOS
Welcome User
Type 'exit' or 'quit' to stop the program
Type 'help' or 'info' for general help
EOS

# heap values must be loaded by OS
# ptr HEAP_OFFSET = 0x1000
# lng HEAP_SIZE   = 0x8000

block_total_size = 0
block_used_size = 0
block_free_size = 0
block_size_in_bytes = 0

struct Block {lng offset, lng size, int16 flag}

Block main_block = Block.new

def init_heap
  main_block.offset = 0
  main_block.size = HEAP_SIZE - Block.length
  main_block.flag = BLK_FIRST | BLK_LAST | BLK_FREE
end
def find_free_block(lng size)
  b = main_block.adr
  loop do
    t = Block(Pointer(b))
  end
end
def alloc_block(lng size, byte fill = 0)
end
def free_block(Block block)
end

Mem.write(HEAP_OFFSET, main_block)

y = Block(size = 3, next = 4, flag = 0)
a = "Matahari tak mungkin hilang"
Mem.write(x.addr + 4, a)
