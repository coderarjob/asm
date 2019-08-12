; This is a kernel Proof of concept.
; The aim is to be able to make a IVT (interrupt vector table) entry of one of
; our system call and be able to make a call to it.

; Our kernel will load at an offset 0, so no ORG is necessery

	org 0x64
_init:
	retf

	; install the putchar into the IVT
	mov ax, 0
	mov es, ax
	mov [es:0xC0],word putchar
	mov [es:0xC2],word 0x800

	; use the system call
	mov ah,0x9
	mov al,[welcomemsg]
	int 0x30

	jmp $

; It will write a character in AX to the screen buffer
putchar:
	push es
	push bx

	mov bx,0xb800
	mov es,bx
	mov [es:0],al
	mov [es:1],ah

	pop bx
	pop es
	iret

welcomemsg: db 'Welcome to Megha kernel',10,13
	    db 'Version: 0.001',0
