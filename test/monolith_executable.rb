

TESTPROG = File.join(File.dirname(__FILE__), '..', 'test_support', 'dumpinfo')
TESTSRC = "#{TESTPROG}.rb"
TESTBIN = "#{TESTPROG}.#{$$}.exe"   # <- .exe suffix for ease of cleanup

def monolith(*args)
  path = File.join( File.dirname( Monolith.whereami ), 'monolith' )
  return `#{path} #{args.join(' ')}`
end

def abspath(path)
  absdir = Dir.chdir( File.dirname( path ) ) { Dir.pwd }
  return File.join(absdir, File.basename(path))
end


# This is a test for the test itself, but why not?
assert("monolith - file paths") do
  assert_true( File.exist?( TESTSRC ) )
end

assert("monolith - basic running") do
  output = monolith '--help'
puts "output='#{output}'\n\n\n"  
  assert_true( $?.exited? )
  assert_true( $?.success? )
  assert_true( output.include? '--runner' )
end

assert("monolith - invalid input") do

  # Bogus option
  output = monolith *%w{--bogus-option #{TESTSRC}}
  assert_true( $?.exited? )
  assert_false( $?.success? )

  # No input file
  output = monolith
  assert_true( $?.exited? )
  assert_false( $?.success? )

  # Valid option but no input file
  output = monolith *%W{--output #{TESTBIN}}
  assert_true( $?.exited? )
  assert_false( $?.success? )

  # TO DO:
  # Invalid runner path
  # Invalid compiler path

end

assert("monolith - building") do
  monolith %W{ #{TESTSRC} --strip --output #{TESTBIN} }
  assert_true( $?.exited? )
  assert_true( $?.success? )

  # Ensure it runs and outputs the expected results.
  results = `#{TESTBIN}`
  assert_true( $?.exited? )
  assert_true( $?.success? )

  assert_equal("$0=", results[0..2])

  lines = results.split("\n")
  assert_equal(lines[1], "ARGV=[]")
  assert_equal(lines[4], "Monolith::IsApp=true")

  wmi, path = lines[5].split("=")
  assert_equal("Monolith.whereami", wmi)

  assert_equal(abspath(TESTBIN), abspath(path))
  assert_true( File.exist?( abspath(path) ) )

  File.unlink(TESTBIN)
end


assert("monolith - option tests") do

  # Bogus compiler or runner should fail
  monolith %W{ #{TESTSRC} --output #{TESTBIN} --compiler ./bogus-mrbc}
  assert_true( $?.exited? )
  assert_false( $?.success? )

  monolith %W{ #{TESTSRC} --output #{TESTBIN} --runner ./bogus-runner}
  assert_true( $?.exited? )
  assert_false( $?.success? )

  # '--execute' option should run the result afterward.
  results = monolith %W{ #{TESTSRC} --output #{TESTBIN} --execute}
  assert_true( $?.success? )
  lines = results.split("\n")
  wmi, path = lines[-1].split("=")
  assert_equal("Monolith.whereami", wmi)
  File.unlink(TESTBIN)

  # legit --compiler and --runner should succeed.  (TODO: make copies
  # of the programs and use those instead.)
  mrbc = File.join( File.dirname( Monolith.whereami ), 'mrbc' )
  runner = File.join( File.dirname( Monolith.whereami ), 'monolith_run' )
  default_output = monolith %W{ #{TESTSRC} --output #{TESTBIN}
                               --runner #{runner} --compiler #{mrbc} }
  assert_true( $?.success? )

  #     confirm that the built executable runs
  results = `#{TESTBIN}`
  assert_true( $?.success? )
  assert_false( results.empty? )
  File.unlink(TESTBIN)

  # --verbose should produce at least as much output as without
  verbose_out = monolith %W{ #{TESTSRC} --output #{TESTBIN} --verbose}
  assert_true( $?.success? )
  assert_true( verbose_out.size > default_output.size )
  File.unlink(TESTBIN)

end
