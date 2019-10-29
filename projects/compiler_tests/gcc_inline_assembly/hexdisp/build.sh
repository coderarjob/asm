#!/bin/sh

	#-fno-pie  					# PIE or PIC stands for Position Independent
								# Code. The offsets of functions and variables
								# are stored in a Global Offset table. As we
								# want flat binary, the GOT will not be part of
								# this. 
								
	#-fno-stack-protector 		# disables the stack smassing protection
								# this is done because the __stack_chk_fail()
								# which is part of ld library is no longer
								# used.

	#-Os 						# Optimize the code for size. -Os enables all
								# -O2 optimizations except those that can
								# increase code size.
								# https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#Optimize-Options

	#-nostdlib 					# Do not use the standard startup files or
								# libraries when linking.Only the libraries
								# that we provide will be passed to the linker.
								# Equivallent to: -nolibc & -nostartfiles
								# https://blogs.oracle.com/linux/hello-from-a-libc-free-world-part-2-v2

	#-ffreestanding 			# Assets that compilation targets a
								# freestanding environment. This implies
								# -fno-builtin. 
								# A freestanding environment is one in which 
								# the standard library may not exist, and 
								# program startup may not necessarily be at 
								# main.
								# https://gcc.gnu.org/onlinedocs/gcc/C-Dialect-Options.html#C-Dialect-Options

	#-m32 						# Generates code for 32 bit environment.
	#-march=i386 				# Generates instructions for an i386 machine.
	#-Wl,
		#--nmagic,
		#--script=simple_dos.ld
	#main.c -o main.com

gcc -fno-pie  \
	-fno-stack-protector \
	-Os \
	-nostdlib \
	-m16 \
	-march=i386 \
	-ffreestanding \
-Wl,--nmagic,--script=simple_dos.ld main.c -o main.com

gcc -S -fno-pie -Os -nostdlib -ffreestanding -m32 -march=i386 \
-Wl,--nmagic,--script=simple_dos.ld main.c -o main.s
