/*
** mrb_whereami.c - MRuby bindings to whereami.
**
** Copyright (c) Chris Reuter 2021
**
** See Copyright Notice in LICENSE
*/

#include "mruby.h"
#include "mruby/data.h"
#include "mrb_whereami.h"

#include "platform_whereami.h"

#include <stdlib.h>

#define DONE mrb_gc_arena_restore(mrb, 0);

// Return a string containing the full path to this executable.  It
// should not be freed.  On error, the result will be an empty string.
//
// (This is not a memory leak because the result needs to be available
// for the life of the process.  However, it's calloc'd and never
// freed so it looks like one.  If your static analysis tool reports
// this, just mark it WONTFIX and move on.)
const char *
whereAmI() {
    static const char *result = NULL;

    if (result) { return result; }

    result = "";

    // Get the length of the result.
    int len = wai_getExecutablePath(NULL, 0, NULL);
    if (len < 0) {
        return result;
    }

    // Get the path and store it.
    char *tmp_result = calloc(len + 1, 1);
    if( wai_getExecutablePath(tmp_result, len, NULL) >= 0) {
        result = tmp_result;
    }

    return result;
}// whereAmI

static mrb_value mrb_whereami(mrb_state *mrb, mrb_value self)
{
    return mrb_str_new_cstr(mrb, whereAmI());

    (void)self; // Suppress unused-variable warning
}


void mrb_mruby_bin_monolith_gem_init(mrb_state *mrb)
{
    struct RClass* mlm = mrb_define_module(mrb, ML_MODULE);

    mrb_define_class_method(mrb, mlm, ML_WMI, mrb_whereami,
                            MRB_ARGS_NONE());

    mrb_define_const(mrb, mlm, ML_APP_FLAG, mrb_false_value());

    mrb_gc_arena_restore(mrb, 0);
}

void mrb_mruby_bin_monolith_gem_final(mrb_state *mrb)
{
}
