#!/bin/bash

BUILD_MODE=$1
if [ "$BUILD_MODE" != "debug" ] && [ "$BUILD_MODE" != "release" ]; then
    echo Error: Unknown run mode: "$BUILD_MODE". Use "debug" or "release".
    exit 1
fi

. ./config.sh

CURRENT_DIR=$(cd -- "$(dirname -- "$0")" &> /dev/null && pwd)

BUILD_ROOT=$CURRENT_DIR/$BUILD_DIR_NAME
mkdir -p "$BUILD_ROOT"

BUILD_DIR=$BUILD_ROOT/$BUILD_MODE
mkdir -p "$BUILD_DIR"

DEBUG_FLAG=""
if [[ "$BUILD_MODE" == "debug" ]]; then
    DEBUG_FLAG="-debug"
fi

"$CURRENT_DIR/$GEN_SCRIPT" $BUILD_MODE
odin build "$CURRENT_DIR/$SRC_DIR" -out:"$BUILD_DIR/$APP_NAME" -build-mode:exe $BUILD_FLAGS $DEBUG_FLAG

if [ $? -ne 0 ]; then
    echo Odin build failed.
    exit -1
fi

echo
echo Build successful!
echo Copying resource files to $BUILD_DIR/$RES_DIR...

mkdir -p "$BUILD_DIR/$RES_DIR"
cp -r "$CURRENT_DIR/$RES_DIR" "$BUILD_DIR"

echo
echo Done.
