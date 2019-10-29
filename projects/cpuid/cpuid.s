
section .text
	global _start

_start:
	mov eax, 0
	cpuid

	mov [string1], ebx
	mov [string1 + 4], edx
	mov [string1 + 8], ecx

	mov eax, 4 ; write system call
	mov ebx, 1 ; write to stdout
	mov ecx, string1
	mov edx, string1.len
	int 0x80

	mov eax, 1 ; exit system call
	xor ebx, ebx
	int 0x80

section .data
string1: times 13 db 10
string1.len: equ ($ - string1)
