# Rakefile for gem development.

MRUBY_CONFIG=File.expand_path(ENV["MRUBY_CONFIG"] || "test_build_config.rb")
MRUBY_VERSION=ENV["MRUBY_VERSION"] || "master"

file :mruby do
  sh "git clone --depth=1 git://github.com/mruby/mruby.git"
  if MRUBY_VERSION != 'master'
    Dir.chdir 'mruby' do
      sh "git fetch --tags"
      rev = %x{git rev-parse #{MRUBY_VERSION}}
      sh "git checkout #{rev}"
    end
  end
end

desc "compile binary"
task :compile => :mruby do
  sh "cd mruby && rake all MRUBY_CONFIG=#{MRUBY_CONFIG}"
end

desc "test"
task :test => :mruby do
  sh "cd mruby && rake all test MRUBY_CONFIG=#{MRUBY_CONFIG}"
end

desc "cleanup"
task :clean do
  sh "cd mruby && rake deep_clean" if File.directory?('mruby')
  sh "rm -rf *.lock test_support/*.mrb tools_ruby/*/*.mrb"
end

task :default => :compile

desc "thorough cleanup; gemdev only"
task :spotless => :clean do
  sh "rm -rf mruby *.lock"
end
