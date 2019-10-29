section .text
	global _start

_start:
	push byte 4
	push byte 2
	push word 8
	push 5
	pop eax
	pop ax
	pop bx
	ret
