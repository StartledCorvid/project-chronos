#!/bin/bash

<<<<<<< Updated upstream
basedir=$(dirname $0)

if [ ! -d "$basedir/builds" ]; then
    mkdir $basedir/builds
fi

outdir=$basedir/builds/$1

if [ $1 == "debug" ]; then

    if [ ! -d $outdir ]; then
        mkdir $outdir
    fi

    exec $basedir/gen.sh debug
    exec odin build game -debug -out:$outdir/Chronos -build-mode:exe -show-timings -subsystem:console -strict-style -vet-unused -vet-style -vet-semicolon

elif [ $1 == "release" ]; then

    if [ ! -d $outdir ]; then
        mkdir $outdir
    fi

    exec $basedir/gen.sh release
    exec odin build game -out:$outdir/Chronos -build-mode:exe -show-timings -subsystem:console -strict-style -vet-unused -vet-style -vet-semicolon

else
    echo "Error: Unknown build mode '$1'. Use 'debug' or 'release'."
    exit -1
fi

if [ $? != 0]; then
    echo 
    echo "Odin build failed."
    exit -1 $?
fi

exec cp -r $basedir/res $outdir/
=======
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
>>>>>>> Stashed changes
