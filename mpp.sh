#!/bin/sh

# Shell script for running MS Project Viewer from the command prompt in linux

# you must specify the programDir directly instead
#programDir=/path/to/jarDir
programDir=$(cd $(dirname $0);pwd)/jar/RationalPlanViewer

cd "$programDir"
sh RationalPlan.sh

