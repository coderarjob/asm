
	org 0x100

	xor ax, ax
	clc
	int 0x12

	nop
	mov ah, 0x4c
	xor al, al
	int 0x21
