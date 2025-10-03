#!/bin/bash

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
