pause: pause.o
	ld -m elf_i386  pause.o -o pause

pause.o: pause.asm 
	nasm -g -f elf32 pause.asm -o pause.o
