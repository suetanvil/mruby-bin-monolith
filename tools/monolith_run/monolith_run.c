

// Monolith runner
//
// This program exists to invoke the mruby interpreter on whatever
// mruby bytecodes have been appended to its executable file.  It does
// this by using whereAmI() to find its location, opening the file and
// reading up to the end of a barrier string (as defined in barrier.h)
// and then handing the file handle to mrb_load_irep_file().
//
// It can also does miscellaneous other useful things to aid in
// constructing self-contained executables.

#include "barrier.h"

#include <mruby.h>
#include <mruby/array.h>
#include <mruby/variable.h>
#include <mruby/dump.h>

#include <mrb_whereami.h>   // <- for whereAmI()

#include <stdlib.h>
#include <assert.h>
#include <stdbool.h>

// Expected name of this executable when not part of a Ruby program.
#define EXE_NAME "monolith_run"

static void
die(const char* message) {
    fprintf(stderr, "Fatal error: %s\n", message);
    exit(1);
}

static bool
looksLikeBaseRunner(const char* exepath) {
    char *path = strdup(exepath);
    if (!path) { die("Out of memory!"); }

    // Discard trailing ".exe" or ".bin" if present
    size_t pl = strlen(path);
    if (pl > 4 &&
        (strcasecmp(".exe", &path[pl - 4]) == 0 ||
         strcasecmp(".bin", &path[pl - 4]) == 0)
        )
    {
        path[pl - 4] = '\0';
        pl -= 4;
    }

    bool result = strcasecmp(EXE_NAME, &path[pl - strlen(EXE_NAME)]) == 0;
    free(path);

    return result;
}



static bool
advanceToBarrier(char *barrier, FILE *fh) {
    char *here = barrier;

    while(true) {
        if (ferror(fh)) { die("Error reading executable."); }
        if (feof(fh)) { return false; }

        char c = fgetc(fh);
        if (c == *here) {
            ++here;
            if (!*here) { break; }
        } else {
            here = barrier;
        }
    }// while

    // Consume the newline; tolerate CR+LF and LF
    if (fgetc(fh) == '\r') {
        fgetc(fh);
    }

    return true;
}// advanceToBarrier



static FILE *
fopenToCodeStart(const char *exepath) {
    FILE *fh = fopen(exepath, "rb");
    if (!fh) {
        die("Unable to open executable!");
    }

    char *barrier = get_barrier();

    bool foundIt = advanceToBarrier(barrier, fh);
    if (!foundIt) {
        fclose(fh);
        return NULL;
    }

    return fh;
}// fopenToCodeStart


static void
createConfigModule(mrb_state *mrb, bool is_app)
{
    struct RClass* mc = mrb_module_get(mrb, ML_MODULE);

    mrb_define_const(mrb, mc, ML_APP_FLAG,
                     is_app ? mrb_true_value() : mrb_false_value());
}



// Set up the interpreter's state to reflect being run as a
// command-line tool (i.e. mruby with a script argument).
static void
setupAsCmdlineTool(mrb_state *mrb,
                      mrbc_context *cxt,        // Initial load context
                      int argc, char* argv[])
{
  mrb_value ARGV;

  // Set ARGV
  ARGV = mrb_ary_new_capa(mrb, argc - 1);
  for (int i = 1; i < argc; i++) {
    char* utf8 = mrb_utf8_from_locale(argv[i], -1);
    if (utf8) {
      mrb_ary_push(mrb, ARGV, mrb_str_new_cstr(mrb, utf8));
      mrb_utf8_free(utf8);
    }
  }
  mrb_define_global_const(mrb, "ARGV", ARGV);

  // Set $DEBUG
  mrb_gv_set(mrb, mrb_intern_lit(mrb, "$DEBUG"), mrb_bool_value(false));

  // Set context flags
  //cxt->dump_result = dump_result;
  //cxt->no_exec = check_syntax;
  (void)cxt;

  // Set $0 and the context's filename.
  const char *cmdline;
  cmdline = argv[0];

  //mrbc_filename(mrb, cxt, cmdline);
  mrb_gv_set(mrb, mrb_intern_lit(mrb, "$0"), mrb_str_new_cstr(mrb, cmdline));
}// setupAsCmdlineTool



static int
launchMRuby(int argc, char *argv[], FILE *bytecodes, bool is_app,
           const char* exepath) {
    mrb_state *mrb = mrb_open();
    if (!mrb) {
        die("Internal error: Can't create context!");
    }

    mrbc_context *cxt = mrbc_context_new(mrb);
    setupAsCmdlineTool(mrb, cxt, argc, argv);

    createConfigModule(mrb, is_app);
    
    // Read and execute the mrb chunks until we reach EOF.  The
    // expectation is that call to main is at the end.
    while(true) {
        mrb_value v = mrb_load_irep_file(mrb, bytecodes);

        // Print an error message (if present) and exit if an error
        // occurred.
        if (mrb->exc) {
            if (!mrb_undef_p(v)) {
                mrb_print_error(mrb);
            }

            return EXIT_FAILURE;
        }

        // See if we're at EOF; we need to do a read for this to work.
        int c = getc(bytecodes);
        if (feof(bytecodes)) { break; }
        ungetc(c, bytecodes);
    }

    fclose(bytecodes);

    mrb_close(mrb);
    return 0;
}


bool
runAsTool(int argc, char *argv[]) {
    const char *cmd = argv[1];

    // The argument must begin with '--' to be treated as an option.
    if (strncmp("--", cmd, 2) != 0) {
        return false;
    }

    // Currently there are only two options so I'm not doing anything
    // clever.

    // Case 1: --print-barrier
    if (strcmp("--print-barrier", cmd) == 0) {
        printf("%s\n", get_barrier());
        return true;
    }

    // Case 2: --help
    if (strcmp("--help", cmd) == 0) {
        printf("USAGE: %s [--help|--print-barrier|<program.mrb> ... args]\n",
               EXE_NAME);
        return true;
    }

    return false;
}// runAsTool


// Load and execute the byte-compiled Ruby code passed as the first
// argument as closely as possible to the ordinary run.
int
runCompiled(int argc, char *argv[], const char* exepath) {

    // We treat the .mrb as the executable
    argc--;
    argv++;

    // Sanity check: ensure the .mrb has the expected extension.
    const char *filename = argv[0];
    size_t fnlen = strlen(filename); 
    if (strcasecmp(".mrb", &filename[fnlen - 4]) != 0) {
        die("Filename doesn't look like compiled mruby.");
    }
    
    FILE *bytecodes = fopen(filename, "rb");
    if (!bytecodes) { die("Unable to open input file."); }
    return launchMRuby(argc, argv, bytecodes, false, exepath);
}// runCompiled


int
main(int argc, char *argv[]) {
    const char *standalone_msg = EXE_NAME " does nothing by itself!";
    int status = 0;
    
    // Find the path of this executable.
    const char *exepath = whereAmI();
    if (*exepath == 0) {
        // If we get here, there's probably a bug in
        // platform_whereami.c
        die("Unable to find executable path!");
    }
    
    // Case 1: this is a standalone executable.
    FILE *bytecodes = fopenToCodeStart(exepath);
    if (bytecodes) {
        status = launchMRuby(argc, argv, bytecodes, true, exepath);
        return status;
    }

    // Case 2: the bytecode got mangled or removed.
    if (!looksLikeBaseRunner(exepath)) {
        die("Bytecode missing; corrupted executable?");
    }

    // Case 3: run standalone with no arguments.
    if (argc < 2) {
        die(standalone_msg);
    }

    // Case 4: do various utility things
    if (runAsTool(argc, argv)) {
        return status;
    }
    
    // Case 5: used as a standalone interpreter
    status = runCompiled(argc, argv, exepath);

    return status;
}
