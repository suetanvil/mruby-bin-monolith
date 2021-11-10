# Test the Monolith module

assert("Monolith#namespace") do
  assert_true( Module.const_defined?(:Monolith) )
  assert_equal(Monolith::IsApp, false)
  assert_equal( String, Monolith.whereami.class )
end

assert("Monolith#whereami") do
  path = Monolith.whereami
  assert_false( path.empty? )

  assert_true( File.exist?(path) )
  assert_equal(path, ENV['_TESTRUNNER'])    # set by teh rgem rakefile
end

