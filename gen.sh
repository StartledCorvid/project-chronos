#!/bin/bash

BUILD_MODE=$1
if [ "$BUILD_MODE" != "debug" ] && [ "$BUILD_MODE" != "release"]; then
    echo Error: Unknown run mode: "$BUILD_MODE". Use "debug" or "release".
    exit 1
fi

. ./config.sh

CURRENT_DIR=$(cd -- "$(dirname -- "$0")" &> /dev/null && pwd)
if [ "$GEN_ROOT" == "" ]; then
    echo No code gen directory provided. Skipping.
    exit 0
fi

if [ ! -d "$CURRENT_DIR$GEN_DIR" ]; then
    echo No code gen directory "$GEN_DIR" detected. Skipping.
    exit 0
fi

echo Generating code. . .

DEBUG_FLAG=""
if [ "$BUILD_MODE" == "debug" ]; then
    DEBUG_FLAG="-debug"
fi

odin run "$CURRENT_DIR$GEN_DIR" $DEBUG_FLAG

if [ $? -ne 0 ]; then
    echo
    echo Odin build failed for gen.
    exit 1
fi

echo . . . Done generating code.
