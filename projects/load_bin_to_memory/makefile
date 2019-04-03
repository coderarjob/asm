exec: exec.o
	ld -m elf_i386 exec.o -o exec

exec.o: exec.s
	nasm -f elf32 -g exec.s -o exec.o


