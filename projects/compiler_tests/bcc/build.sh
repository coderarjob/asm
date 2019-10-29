bcc -ansi -0 -W -c main.c -o main.o
bcc -ansi -0 -W -S main.c -o main.s
ld86 -d main.o -o main.com -T0
