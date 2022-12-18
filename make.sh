#!/bin/bash
nasm -f elf src/edlin.asm -o bin/edlin.o
ld -m elf_i386 bin/edlin.o -o bin/edlin
rm bin/edlin.o
