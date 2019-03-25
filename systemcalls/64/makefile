s64: s64.o
	ld -o s64 s64.o
s64.o: s.asm
	nasm -f elf64 -F stabs -g s.asm -o s64.o -l s.list
