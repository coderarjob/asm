; Dos application for testing VGA mode 13
	

	org 0x100

	; enter mode 13
	mov ah, 0
	mov al, 0x13
	int 0x10

	; fill the screen with a color
	mov ax, 0xA000
	mov es, ax
	mov di, 0x0
	mov al, 0x4	; white
	mov cx, 320*200
	rep stosb

	; wait for a keystroke
	mov ah,0
	int 0x16

	; restore text mode
	mov ah, 0
	mov al, 3
	int 0x10

	; exit to dos
	mov ah, 0x4c
	mov al, 0
	int 0x21



