	
		org 0x100

		; 80x25 text display (mode 3)
		mov ah, 0
		mov al,03
		int 0x10
		; setup the segment register
		mov ax, 0xB800
		mov es, ax

		; draw the headers
drawheader:
		mov si, headerchars
		mov bx, 166	; row 1, column 3
		mov di, 322	; row 2, column 2
		mov cx, 16
.again:
		lodsb
		mov [es:bx],al	; column header
		mov [es:di],al	; row header
		add bx, 4
		add di, 160
		loop .again
		
		jmp drawchars1

		; draw the characters
drawchars:
		mov cx, 255
		mov al, 0
		mov ah, 16 	; or ax = 0x1000
		mov bx, 326	; row 2, column 3
.again:
		mov [es:bx], al
		mov [es:bx + 1], byte 0xE
		add bx,4
		add ax,0x101
		and ah,0xF
		loopnz .again
		add bx,96
		jcxz keypress
		jmp .again

drawchars1:
	mov ax,0
	mov bx, 326		; row 2, column 3
.again:
	mov [es:bx], al
	mov [es:bx+1],byte 0x5
	add bx,4
	add al,1
	test al,0xF
	jnz .again
	add bx,96
	test al,0xFF
	jnz .again
	
	; wait for keystorke
keypress:
	mov ah,0
	int 0x16

	; change to normal mode
	; exit
	mov ah, 0x4c
	mov al, 0
	int 0x21

	headerchars:	db	'0123456789ABCDEF'
