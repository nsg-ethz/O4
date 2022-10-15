#!/bin/bash
# requirement: #lang halstead/p4 already added at top of file

for filename in code/examples/tna/*2022*.p4; do
	echo "$filename"
	racket "$filename"
done

for filename in code/examples/v1model/*2022*.p4; do
        echo "$filename"
	racket "$filename"
done
