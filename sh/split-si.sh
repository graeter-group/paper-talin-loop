#!/bin/env bash

pdfseparate -f 12 index.pdf si-page%d.pdf
pdfunite si-page*.pdf supplementary.pdf
rm si-page*.pdf

