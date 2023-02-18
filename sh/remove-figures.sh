#!/bin/env bash

cat index.tex |
  sed '1577,1919d' |
  grep -v includegraphics > manuscript-no-figures.tex

xelatex manuscript-no-figures.tex
xelatex manuscript-no-figures.tex

