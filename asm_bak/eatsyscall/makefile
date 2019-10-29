eatsyscall: eatsyscall.o
	ld -o eatsyscall eatsyscall.o

eatsyscall.o: eatsyscall.asm
	nasm -f elf64 -F stabs -g eatsyscall.asm -o eatsyscall.o
