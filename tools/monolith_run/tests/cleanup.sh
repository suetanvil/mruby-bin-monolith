#!/bin/bash

set -e

for rb in *.rb; do
    rm ${rb%.rb}.mrb ${rb%.rb}
done

[ -f last_result.txt ] && rm last_result.txt
