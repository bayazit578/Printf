#!/bin/bash

mkdir -p compiled
nasm -g -f elf64 -l compiled/stdo.lst stdo.asm -o compiled/stdo.o
gcc -g -no-pie -o compiled/print_f test.cpp compiled/stdo.o
./compiled/print_f
