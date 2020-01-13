#!/bin/sh

set -e

TEST_EXE="$1"
CORECTL_EXE="$2"
COREHELPER_EXE="$3"
COREDUMP_TEST_PATH="$4"

trap "rm -rf $COREDUMP_TEST_PATH" EXIT

if [ ! -f "test_core" ]; then
    gdb --exec "$TEST_EXE" --batch -ex run -ex "generate-core-file test_core"
fi

cat "test_core" | "$COREHELPER_EXE" -e "test" -X "!test!test" -g 1000 -u 1000 -p 55 -s 6 -t 1
"$CORECTL_EXE" list
"$CORECTL_EXE" info 1
