; DOS application that demonstrates the Text User interface using bios calls
; Dated: 29/03/2019
; Authors: Arjob Mukherjee (arjobmukherjee@gmail.com)
; Build:
; nasm -f bin -o tui.com tui1.s

	org 0x100
	
	; set 80x25 character mode
	mov ah,00
	mov al,03
	int 10h

	; EXPERIMENTAL: get to the 8x8 character mode
	mov ax, 0x1112
	mov bl, 0
	int 10h

	; print the welcome message
	mov si,welcomemsg
	call printstr

	; print the waiting for keypress message
	mov si,pressanykey
	call printstr

	; wait for key stroke
	mov ah,00
	int 0x16
	
	; restore the mode
	mov ah,00
	mov al,03
	int 0x10

	; exit dos
	mov ah, 0x4c
	mov al, 00
	int 21h

; Displays a text at the top of the screen
; Input:
; DS:SI points to the string
printstr:		
	push AX
	push BX
	
	mov bx, 0	;page 0, 0 foreground
.loop:	
	lodsb
	cmp al,0
	jz .end
	mov ah,0xE
	int 10h
	jmp .loop
.end:
	pop BX
	pop AX
	ret
welcomemsg:	db	'Welcome to TUI demostration',10,13
		db	'Version: 2019.3.29A',10,10,13,0

pressanykey:	db	'Press any key to continue',10,13,0
