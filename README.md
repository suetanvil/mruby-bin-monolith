# mruby-bin-monolith

Create standalone executables from your MRuby scripts without
a C/C++ toolchain.


## How it works

The major operating systems' executable file formats all ignore data
that has been appended to the file.  This means that an executable
with mrb data appended to it will work fine; the operating system
loader will ignore it.

Monolith adds an executable (`monolith_run`) linked against MRuby
(plus whatever mgems have been added) that

1. finds its own executable
2. opens it for reading and seeks ahead to the end of a special
   barrier string.
3. sets up an mruby interpreter, and
4. loads the rest of the executable into it as bytecodes and runs
   them.

So by appending one or more byte-compiled MRuby (`.mrb`) files to it,
you can easily create a self-contained single file executable version
of your MRuby program.


## Tools

This gem creates two standalone tools, `monolith` and `monolith_run`.
The latter can mostly be ignored but is documented below for
completeness.


### monolith

`monolith` is the build tool.  Given one or more mruby source files on
the command line, it will produce an executable:

    $ echo 'puts "Hello!"' > a.rb
    $ echo 'puts "World"' > b.rb
    $ monolith a.rb b.rb
    $ ./b
    Hello!
    World

The executable's name is taken from the last input file.  You can
override this with the `--output` flag:

    $ monolith a.rb b.rb --output hi
    $ ./hi
    Hello!
    World

It will also accept compiled mruby (`.mrb`) files:

    $ monolith a.mrb b.mrb --output hi2
    $ ./hi2
    Hello!
    World

If your workflow centers around rapidly recompiling and running your
program, you may benefit from the `--execute` option, which will
execute the program after it has successfully been compiled:

    $ monolith a.mrb b.mrb --execute
    Hello!
    World

#### Option Reference

* `-v/--verbose`
  * Display more messages.
* `-r/--runner PATH`
  * Use the file at PATH instead of the default (a
    file named `monolith_run` in directory containing the `monolith`
    executable being run.)
* `-o/--output EXE`
  * Write the output file to EXE instead of the default name.
* `-s/--strip`
  * Run `strip` on a copy of `monolith_run` before appending the
    bytecodes.  Some `strip`s get confused by the trailing
    bytecodes so this is an easy way to ship stripped executables
    based on builds of `monolith_run` that still have debug symbols.
* `-c/--compiler PATH`
  * Specify the compiler to use for bytecode-compiling mruby source
    code instead of the default (the `mrbc` located in the same
    directory as `monolith`).
* `-e/--execute`
  * Execute the resulting program on success.

### monolith_run

`monolith_run` is intended to be the start of a standalone mruby
program.  It opens its own executable, searches for a known barrier
string and then treats everything following it as MRuby bytecodes.
These are read and executed more or less the same way `mruby` would.

If run by itself with no arguments, it will print an error message and
exit with a non-zero status.

If run with only the argument `--print-barrier`, it will output the
barrier string that it searches for.  This is used by `monolith` when
assembling an executable.

Note that `monolith_run` does **not** do Unix-style argument parsing;
`--print-barrier` is a special case.  (So is `--help`.)

Finally, if `monolith_run` is run with one or more compiled MRuby
(`.mrb`) files on the command line, it will load and run them.  (This
is probably not very useful.)



## Modules

### module Monolith

In a flagrant violation of the guideline against mixing extensions and
tools, Monolith also provides a module (named `Monolith`) that adds
a couple of items to the mruby environment.  These are intended for
development and/or debugging your compiled scripts.

#### Members

* `Monolith.whereami() -> string`
  * Returns the absolute path to the native-code executable being run.
    This invokes the same function `monolith_run` uses to find its own
    executable.

* `Monolith::IsApp -> boolean`
  * `true` if the current program is a standalone compiled Ruby
    program; false otherwise.  Constant.


## Installation via mrbgems

Simply add this conf.gem line to `build_config.rb`:

```ruby
MRuby::Build.new do |conf|

    # ... (snip) ...

    conf.gem :github => 'suetanvil/mruby-bin-monolith',
             :branch => 'main'
end
```

Note that this gem depends on a number of other external mrbgems which
in turn end up importing most(?) of the core gembox.  This will
produce a featureful but large `mruby` build.


## License

Released under the MIT License. See the `LICENSE` and `AUTHORS` files.
