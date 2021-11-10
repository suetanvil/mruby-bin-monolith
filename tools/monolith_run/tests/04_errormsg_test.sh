#!/bin/bash

set -e

# Doesn't actually do a backtrace, alas.
./backtrace 2>&1 || true
