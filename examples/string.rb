# test String.concat
puts("* Test String.concat")
a = "Com"
b = "Put"
c = "Ing"
d = a.concat(b).concat(c)
puts(d)
puts("")

# test String.append
puts("* Test String.append")
d = "Com"
puts(d.append(b).append(c))
puts("")

# test String.lcase
puts("* Test lcase")
puts(d.lcase)
puts("")

# test String.ucase
puts("* Test ucase")
puts(d.ucase)
puts("")

# test String.substr
puts("* Test substr")
puts("COMPUTING".substr(3, 5))

_unassign_object(a)
_unassign_object(b)
_unassign_object(c)
_unassign_object(d)
_collect_garbage()
