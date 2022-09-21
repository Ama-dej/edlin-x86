#!/bin/bash
nasm -f elf edlin.asm -o edlin.o
ld -m elf_i386 edlin.o -o edlin
