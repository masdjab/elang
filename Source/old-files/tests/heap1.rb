# code sample

int16 BLK_FREE = 0
int16 BLK_USED = 1
int16 BLK_FIRST = 2
int16 BLK_LAST = 4

ERR_OUT_OF_MEMORY = "Out of memory"

  ###
  greeting message
  ###
  
WelcomeMessage = <<EOS
Welcome User
Type 'exit' or 'quit' to stop the program
Type 'help' or 'info' for general help
EOS

# heap values must be loaded by OS
# ptr HEAP_OFFSET = 0x1000
# lng HEAP_SIZE   = 0x8000

lng block_total_size
lng block_used_size
lng block_free_size
lng block_size_in_bytes

struct Block {lng offset, lng size, int16 flag}

Block main_block = Block.new

void init_heap
  main_block.offset = 0
  main_block.size = HEAP_SIZE - Block.length
  main_block.flag = BLK_FIRST | BLK_LAST | BLK_FREE
end
Block find_free_block(lng size)
  b = main_block.adr
  loop do
    t = Block(Pointer(b))
  end
end
Block alloc_block(lng size, byte fill = 0)
end
bool free_block(Block block)
end

Mem.write(HEAP_OFFSET, main_block)

y = Block(size = 3, next = 4, flag = 0)
a = "Matahari tak mungkin hilang"
Mem.write(x.addr + 4, a)
