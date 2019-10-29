#!/bin/sh

gcc -fno-pie -Os -nostdlib -ffreestanding -m32 -march=i386 \
-Wl,--nmagic,--script=simple_dos.ld pointer.c -o pointer.com

gcc -S -fno-pie -Os -nostdlib -ffreestanding -m32 -march=i386 \
-Wl,--nmagic,--script=simple_dos.ld pointer.c -o pointer.s
