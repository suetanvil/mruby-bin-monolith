


MRuby::Gem::Specification.new('mruby-bin-monolith') do |spec|
  spec.bins = %w{monolith_run}
  spec.license = 'MIT'
  spec.authors = 'Chris Reuter'

  spec.add_dependency('mruby-optparse')

  # We want mruby-process2, not mruby-process; unfortunately, rake is
  # currently choking on its entry in mgem-list so we provide an
  # explicit github dependency instead.
  spec.add_dependency('mruby-process', :github => 'katzer/mruby-process')

  spec.add_test_dependency('mruby-dir')

  spec.cc.flags += %W{-I #{File.join(__dir__, 'src')}}


  #
  # Use monolith to build the 'monolith' executable:
  #

  bindir = "#{build.root}/build/#{build.name}/bin"

  ml_exe = exefile("#{bindir}/monolith")
  runner_bin = exefile("#{bindir}/monolith_run")
  mruby_bin = exefile("#{bindir}/mruby")
  mrbc_bin = exefile("#{bindir}/mrbc")
  ml_src = "#{__dir__}/tools_ruby/monolith/monolith.rb"

  desc 'build the "monolith" executable'
  file ml_exe => [runner_bin, ml_src, mruby_bin, mrbc_bin] do
    sh mruby_bin, ml_src, '-c', mrbc_bin, '--runner',  runner_bin,
       '--strip', '--output', ml_exe, ml_src
  end

  task :all => ml_exe

  if build.test_enabled?
    runner = "#{bindir}/mrbtest"
    runner += ".exe" if for_windows?
    ENV['_TESTRUNNER'] = runner
    # ENV['_BINDIR'] = bindir
  end

  # Task to clean up the extra byproducts
  task :clean do
    HERE = File.dirname(__FILE__)
    FileUtils.rm(*Dir.glob("#{HERE}/test_support/*.exe"),
                 *Dir.glob("#{HERE}/test_support/*.mrb"),
                 "#{HERE}/tools_ruby/monolith/monolith.mrb")
  end

end
