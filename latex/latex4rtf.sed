#!/bin/sed -f

# delete comments
/^%/d

# ignore \index{}
s.[\]index{[^}]*}..g

# replace figure* with figure
s.{figure\*}.{figure}.g

# replace table* with table
s.{table\*}.{table}.g

# delete line: redef of cite
/\\def\\cite\#/d

# replace \cite or \citep with \verbatim
s.\\cite[p]*{\([^}]*\)}.\\verb=[\1]=.g

#s.\\abstract.\\section{Abstract}.g

