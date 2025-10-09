#!/bin/bash

. ./config.sh


BASE_DIR=$(dirname $0)
BUILD_DIR=$BASE_DIR/$BUILD_DIR/$1

if [ "$1" == "debug" ]; then

    if [ ! -d $BUILD_DIR ]; then
        echo "Error: No build found for '$1'."
        exit -1
    fi

    ./$BUILD_DIR/%APP_NAME

elif [ "$1" == "release" ]; then

    if [ ! -d $BUILD_DIR ]; then
        echo "Error: No build found for '$1'."
        exit -1
    fi

    ./$BUILD_DIR/%APP_NAME

else
    echo "Error: Unknown build mode '$1'. Use 'debug' or 'release'."
    exit -1
fi