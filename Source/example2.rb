def show_length(text)
  text_info = "text is: " + text
  lgth_info = "size is: " + text.length.to_s
  puts text_info
  puts lgth_info
end

a = "Hello world..."
show_length a
