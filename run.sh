#!/bin/bash

BUILD_MODE=$1
if [ "$BUILD_MODE" != "debug" ] && [ "$BUILD_MODE" != "release" ]; then
    echo Error: Unknown run mode: "$BUILD_MODE". Use "debug" or "release".
    exit 1
fi

. ./config.sh

CURRENT_DIR=$(cd -- "$(dirname -- "$0")" &> /dev/null && pwd)
BUILD_DIR=$CURRENT_DIR/$BUILD_DIR_NAME/$BUILD_MODE

echo Starting application from: $BUILD_DIR
cd "$BUILD_DIR"
"$BUILD_DIR/$APP_NAME"
