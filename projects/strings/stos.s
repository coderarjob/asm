; This is a linux program that demostrates STOS instruction.

section .text
	global _start

%macro printstring 0
	pushad
	mov eax, 4	; write system call
	mov ebx, 0	; stdout
	mov ecx, string
	mov edx, stringlen
	int 0x80
	popad
%endm
_start:
	printstring

	; clear the memory location held by string with anothr byte

	; STOSB copies the byte in EAX register to the memory location in the 
	; ES:EDI register. 
	; The REP prefix repeats the STOSB instruction as many times as the 
	; number in the ECX register.

	mov edi, string
	mov ecx, stringlen
	mov eax, 'a'
	rep stosb

	printstring

	; exit program
	mov eax, 1
	mov ebx, 0
	int 0x80

section .data
string: db "Hello world",10
stringlen: equ $-string
