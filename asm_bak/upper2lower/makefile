s: s.o
	ld -m elf_i386 -o s s.o

s.o: s.asm
	nasm -f elf32 -F stabs -g s.asm -o s.o

64: s64
s64: s64.o
	ld -o s64 s64.o
s64.o: s.asm
	nasm -f elf64 -F stabs -g s.asm -o s64.o
