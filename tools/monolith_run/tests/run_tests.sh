#!/bin/bash

# hacky tests

set -e

export STAGE=../../mruby_build/staging/bin

for rb in *.rb; do
    echo "Compiling $rb..."
    $STAGE/mrbc $rb
    ../mrconstruct --runner ../mrb_run ${rb%.rb}.mrb
done

for t in *_test.sh; do
    echo -n "$t "
    if bash $t 2>&1 > last_result.txt ; then
        true
    else
        echo "RUN FAILED!"
        cat last_result.txt
        break
    fi

    # Fixup any absolute paths. 
    ruby -i util/strip_pwd.rb last_result.txt
    
    if diff -q last_result.txt ${t%.sh}.expected 2>&1 >/dev/null ; then
        echo "PASSED!"
    else
        echo "FAILED!"
        diff last_result.txt ${t%.sh}.expected || true
        break
    fi
done
