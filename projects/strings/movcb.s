; This program demostrates the use of MOVCB instruction
; It copies bytes from one memory location to another.

section .text
	global _start

_start:
	; copies all bytes from STRING to STRING_DEST location
	mov esi, string
	mov edi, string_dest
	mov ecx, string_len
	rep movsb

	; prints STRING_DEST to screen
	mov eax, 4
	mov ebx, 0
	mov ecx, string_dest
	mov edx, string_len
	int 0x80

	; exit program
	mov eax, 1
	mov ebx, 0
	int 0x80

section .data
string: db "Arjob Mukherjee is my name.",10
string_len: equ $ - string

section .bss
string_dest: resb 50
