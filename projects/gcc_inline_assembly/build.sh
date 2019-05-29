#!/bin/sh
gcc -fno-pie -Os -nostdlib -ffreestanding -m16 -march=i386 \
-Wl,--nmagic,--script=simple_dos.ld simple_dos.c -o simple_dos.com
