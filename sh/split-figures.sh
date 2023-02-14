#!/bin/env bash

pdfseparate -f 2 only-figures.pdf figures/figure-%d.pdf

for i in {2..7}; do
  n=$((i-1))
  echo $n
  mv figures/figure-${i}.pdf figures/figure-${n}.pdf
done

