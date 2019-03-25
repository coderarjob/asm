s: s.o
	ld -m elf_i386 -o s s.o

s.o: s.asm
	nasm -f elf32 -F stabs -g s.asm -o s.o -l s.list

