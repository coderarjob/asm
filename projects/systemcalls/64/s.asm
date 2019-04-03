;;; BITS 64 nasm

section .data
	somedata: db "HELLOWORLD",0,10
	somedata.len: equ $-somedata

section .text
	global _start

_start:
	mov rax, 1 ; call _write system call
	mov rdi, 1 ; write to stdout
	mov rsi, somedata
	mov rdx, somedata.len
	syscall

	nop
	mov rax,60
	mov rdi,0
	syscall

