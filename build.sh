#!/bin/bash

. ./config.sh

BASE_DIR=$(dirname $0)

if [ ! -d "$BASE_DIR/$BUILD_DIR" ]; then
    mkdir $BASE_DIR/$BUILD_DIR
fi

BUILD_DIR=$BASE_DIR/$BUILD_DIR/$1

if [ "$1" == "debug" ]; then

    if [ ! -d $BUILD_DIR ]; then
        mkdir $BUILD_DIR
    fi

    $BASE_DIR/gen.sh debug

    odin build game -out:$BUILD_DIR/$APP_NAME -build-mode:exe $BUILD_FLAGS -debug

elif [ "$1" == "release" ]; then

    if [ ! -d $BUILD_DIR ]; then
        mkdir $BUILD_DIR
    fi

    $BASE_DIR/gen.sh release

    odin build game -out:$BUILD_DIR/$APP_NAME -build-mode:exe $BUILD_FLAGS

else
    echo "Error: Unknown build mode '$1'. Use 'debug' or 'release'."
    exit -1
fi

if [ $? -ne 0 ]; then
    echo 
    echo "Odin build failed."
    exit -1
fi

echo
echo "Build successful!"
echo "Copying resource files to '$BUILD_DIR/$RES_DIR'..."

cp -r $BASE_DIR/$RES_DIR $BUILD_DIR/

echo
echo "Done."
