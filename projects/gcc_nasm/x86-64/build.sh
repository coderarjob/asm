


# Builds the assembly file and the C file separatetly and joins them info an
# executable.

nasm -g -f elf64 printString.s -o printString.o||exit 1
#gcc main.c printString.o -o main||exit 2
gcc -g -c main.c -o main.o||exit 2
gcc main.o printString.o -o main
