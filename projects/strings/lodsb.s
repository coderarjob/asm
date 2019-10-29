; Demostrates basic function of LODSB instruction

	org 0x100
	
	mov ax, 0xb800
	mov es, ax
	mov bx, 0

	mov si, string
.rep:
	lodsb
	cmp al, 0
	je .end

	mov [es:bx],al
	mov [es:bx+1],byte 0xE
	add bx,2
	jmp .rep
.end:
	mov ah, 0x4c
	mov al, 0
	int 0x21

string: db "Hello x86 assembly",0
