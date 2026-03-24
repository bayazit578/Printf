#!/bin/bash

mkdir -p compiled
nasm -g -f elf64 -l compiled/stdo.lst stdo.asm -o compiled/stdo.o
ld -o compiled/stdo compiled/stdo.o
./compiled/stdo
