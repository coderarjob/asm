bcc -ansi -W -0 -S main.c -o main.s
bcc -ansi -W -0 -c main.c -o main.o
ld86 -d main.o -o main.com -T100
