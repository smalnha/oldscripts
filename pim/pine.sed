#!/bin/sed -f
s/^"\([^"]*\)","\([^"]*\)","\([^"]*\)","\([^"]*\)","\([^"]*\)","\([^"]*\)","\([^"]*\)","\([^"]*\)","\([^"]*\)"/\4	\3, \1 \2\	\5		/
