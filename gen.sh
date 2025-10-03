#!/bin/bash

if [ $1 == "debug" ]; then
    exec odin run gen -debug
elif [ $1 == "release" ]; then
    exec odin run gen
else
    echo "Error: Unknown build mode '$1'. Use 'debug' or 'release."
    exit -1
fi

if [ $? != 0 ]; then
    echo 
    echo "Odin build failed for gen."
    exit -1 $?
fi
