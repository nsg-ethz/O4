#!/usr/bin/env zsh
for filename in code/examples/(v1model|tna)/*.o4; do
  echo $filename
  for i in {0..2}; do
    time racket $filename
  done
done
