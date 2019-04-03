SECTION .data					; Section contains initialized data

EatMsg: db 27,"[2JEat at Joe's!",10
EatLen: equ $-EatMsg

SECTION .bss					; Section contains uninitialized data
SECTION .text					; Section contains code

global _start					; Linker needs this line to find the entry point

_start:	
	nop							; This keeps the gdb happy
	mov eax, 4					; Specify sys_write system call
	mov ebx, 1					; Specify file descriptor 1 (stdout)
	mov ecx, [EatMsg]
	mov ecx, EatMsg				; Pass offset to the message
	mov edx, EatLen				; Pass the length of th message
	int 80H						; make system call to output text to stdout

	mov eax, 1					; Specify exit system call
	mov ebx, 0					; Return a code of zero
	int 80H						; make the system call
