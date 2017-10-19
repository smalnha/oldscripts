#!/bin/sh

#gs -dNOCACHE -dNOPAUSE -sDEVICE=pswrite -dBATCH -sOutputFile=print.ps print?.ps
gs -dNOCACHE -dNOPAUSE -sDEVICE=pswrite -dBATCH -sOutputFile=merged.ps "$@"


