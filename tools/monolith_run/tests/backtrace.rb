
# Fail with an error deepish in the stack

def foo()
  bar
end

def bar()
  quux
end

def quux()
  baz
end

def baz()
  bobo
end


foo
