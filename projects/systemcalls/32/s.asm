;;; BITS 32 nasm

section .data
	somedata: db "HELLO WORLD",10
	somedata.len: equ $-somedata

section .text
	global _start

_start:
	mov eax, 4 ; call _write system call
	mov ebx, 1 ; write to stdout
	mov ecx, somedata
	mov edx, somedata.len
	int 80H

	nop
	mov eax,1H
	mov ebx,0
	int 80H

