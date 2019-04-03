seg: seg.o
	ld -m elf_i386  seg.o -o seg

seg.o: main.asm
	nasm -g -f elf32 main.asm -o seg.o
