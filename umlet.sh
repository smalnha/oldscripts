#!/bin/sh

# Shell script for running umlet from the command prompt in linux

# If you want to put umlet.sh in your home bin directory ($HOME/bin/) to start it from anywhere with
#    $ umlet.sh myDiagram.uxf
# you must specify the programDir directly instead
#programDir=/path/to/umlet
programDir=$(cd $(dirname $0);pwd)/jar/UMLet

if [ $# -gt 0 ]
 then java -jar ${programDir}/umlet.jar -filename="$1"
 else java -jar ${programDir}/umlet.jar
fi
