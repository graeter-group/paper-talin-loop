#!/bin/env bash

cat index.tex |
  sed '1579,1921d' |
  grep -v includegraphics > manuscript-no-figures.tex

xelatex manuscript-no-figures.tex
xelatex manuscript-no-figures.tex

