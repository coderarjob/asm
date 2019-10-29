
	org 0x100
	
_seg: equ 0x193

	push 1
	push 2
	pop ax
	pop bx

	; install into the ivt
	xor ax, ax
	mov es,ax
	mov [es:0x80],word print
	;mov [es:0x82],word 0x193
	mov [es:0x82],word 0x75C

	mov al,'A'
	int 0x20
	;call 0x193:print
	;call _seg:print

	mov ah, 0
	int 0x16

	mov ax, 0x4c00
	int 0x21
print:
	push es
	push bx

	mov bx,0xb800
	mov es,bx
	mov [es:0],al
	mov [es:1],byte 0xB

	pop bx
	pop es
	;iret
	retf

