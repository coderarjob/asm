
	org 0x100

	mov ax, string
	mov si, ax
	mov ax, 0xb800
	mov es:ax
	mov bx, 0
.again:
	lodsb
.checkend:
	cmp al, 0
	je .end
.checklinefeed:
	cmp al, 13	; LF
	jne .checkCarrageReturn
	add bx, 160	; new line char 10 detected
	jmp .again
.checkCarrageReturn:
	cmp al, 10	; CR
	jne .cont
	xor dx, dx	; carrage return 
	mov ax, bx	; ax = floor(dx:ax)/160
	mov bx, 160
	div bx
	mov bx, ax	; bx = ax * 160
	shl bx, 7	
	shl ax, 5
	add bx, ax
	jmp .again
.cont:				; store the character and attribute in mem
	mov [es:bx], al		; store the character
	mov [es:bx+1],byte 0xf	; store the attribute
	add bx, 2
	jmp .again
.end:				; exit dos
	mov ax, 0x4c00
	int 0x21

string:	db 'Hello I am Arjob', 10, 13
	db 'I live in Pune, India', 10, 13
	db 'I love to program computers',10,13
	db 'I am building an OS and a compiler now',10,13,0
