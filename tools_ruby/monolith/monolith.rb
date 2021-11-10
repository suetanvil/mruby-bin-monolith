
# Tool to create an executable from the runner and one or more mrb
# files.

DefaultRunner = "monolith_run"
DefaultCompiler = "mrbc"

class MsgPrinter
  attr_accessor :verbose
  def initialize
    @verbose = false
  end

  def say(*args)
    puts "#{args.join(" ")}" if @verbose
  end
end

Printer = MsgPrinter.new
def say(*args)
  Printer.say(*args)
end


def die(*args)
  puts args.join(' ')
  exit 1
end

def run(cmd)
  result = IO.popen(cmd) { |fh| fh.readlines }

  die("Error running '#{cmd}':\n    #{result.join}") unless $?.exitstatus == 0
  return result
end

# find runner
def find_exe(exe)
  exepath = File.join( File.dirname(Monolith.whereami), exe )
  return nil unless File.exist?(exepath)
  return exepath
end


def parse_args
  flags = {
    runner: find_exe(DefaultRunner),
    compiler: find_exe(DefaultCompiler),
    output: nil,
    verbose: false,
    strip: false,
    execute: false,
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: monolith [options] files.."

    opts.on("-v", "--verbose", "Run verbosely.") {
      flags[:verbose] = true
    }

    opts.on("-r", "--runner PATH", "Specify alternate runner.") { |r|
      flags[:runner] = r
    }

    opts.on("-o", "--output EXE", "Specify output file.") { |o|
      flags[:output] = o
    }

    opts.on("-s", "--strip", "Run 'strip' on (copied) runner first.") {
      flags[:strip] = true
    }

    opts.on("-c", "--compiler PATH",
            "Path to compiler to use for *.rb files.") { | mrbc |
      flags[:compiler] = mrbc
    }

    opts.on("-e", "--execute", "Execute the resulting program on success.") {
      flags[:execute] = true
    }
  end.parse!(ARGV)

  # Remaining arguments are input filenames
  files = ARGV

  # Sanity check on the input files
  files.size > 0 or die "No input file(s) given."

  # Set the output filename if not specified
  flags[:output] = files[-1].gsub(/\.m?rb$/i, '') unless flags[:output]

  return [flags, files]
rescue OptionParser::ParseError => e
  STDERR.puts "#{e}"
  exit 1
end

def cat(filename, output)

  say "Appending #{filename}..."
  File.open(filename, "rb") { |fh|
    while !fh.eof?
      chunk = fh.read(0x1000)
      output.write chunk
    end
  }
end

def cp(src, dest)
  File.open(dest, "wb") { |fh| cat(src, fh); }
end

def compile(compiler, files)
  update_files = []

  for file in files

    die "File #{file} does not look like compiled mruby bytecode" unless
      file =~ /\.m?rb$/i

    if file =~ /\.rb$/i
      say "Compiling '#{file}'"
      run("#{compiler} #{file}")
    end

    update_files.push file.gsub(/\.m?rb$/i, '.mrb')
  end

  return update_files
end

def link(runner, barrier, files, strip, output)
  say "Linking #{output}..."

  cp(runner, output)
  run("strip #{output}") if strip

  File.open(output, "ab") {|fh|
    fh.write(barrier)
    files.each{|fname| cat(fname, fh) }
  }

  File.chmod(0755, output)
end

def get_barrier(runner)
  barrier = run("#{runner} --print-barrier")[0]
  barrier = barrier.chomp + "\n";
  return barrier
end

def execute(exe)

  # Most *nix OSs won't run an executable in the current directory so
  # we add './' if exe is not a path.
  exe = File.join('.', exe) if exe == File.basename(exe)

  say "Running '#{exe}'"

  # And we use 'system' instead of 'run' because the latter catches
  # stdout and we want the user to see all the output as it happens.
  system(exe) or die "Error running '#{exe}'."
end

def main
  flags, files = parse_args

  # Ensure we can find the external tools
  %i{runner compiler}.each { |tool|
    flags[tool] or
      die("Unable to find the corresponding #{tool}!")
  }

  Printer.verbose = flags[:verbose]
  say "Verbosity enabled."
  say "Runner at '#{flags[:runner]}'"

  barrier = get_barrier(flags[:runner])

  # Compile if needed
  files = compile(flags[:compiler], files)

  # Link
  link(flags[:runner], barrier, files, flags[:strip], flags[:output])

  # Run if requested
  execute(flags[:output]) if flags[:execute]
rescue => e
  puts e
end

main
