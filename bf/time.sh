#!/bin/bash

LANG=s make

for f in $(find progs/ -maxdepth 1 -type f -name "*.b"); do
    echo "Timing for ${f}:"
    if [[ -f "${f%.*}.in" ]]; then
        echo "time bash -c './brainfuck "$1" < "$2" > /dev/null' _ "${f}" "${f%.*}.in""
    else
        time bash -c './brainfuck "$1" > /dev/null' _ "${f}"
    fi
    echo
done
