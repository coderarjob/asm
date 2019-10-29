
	BITS 16

	mov word [eax + 2*4], 7

	mov ah, 0x4c
	mov al, 0
	int 0x21
