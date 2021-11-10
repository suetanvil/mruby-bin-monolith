#!/usr/bin/env ruby

# Quick-and-dirty filter to replace the absolute path to the parent
# directory with '$ROOT'.  This is needed to keep the tests from
# breaking if the code gets checked out in a different directory.

root = File.absolute_path( File.join( File.dirname(__FILE__), '..', '..') )
while line = gets
  line.gsub!(root,'$ROOT')
  print line
end
