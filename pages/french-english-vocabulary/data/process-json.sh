#!/bin/bash

for file in *.json; do \
  filename=$(basename "$file"); \
  extension="${filename##*.}"; \
  filename="${filename%.*}"; \
  sed "1s/^/$filename = /; \$s/\$/;/" <$file >${filename}.js;  \
done
mv *.js ../assets

