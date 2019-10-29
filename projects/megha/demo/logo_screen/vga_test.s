; Dos application that used DOS and vga data area to display an image from a
; raw file.

	org 0x100

	; attemp to open fle
open_image_file:
	mov ah, 0x3d
	mov al, 0		; read only
	mov dx, filename
	int 0x21
	
	mov bx, ax		; save the file handle to bx (used by readfile)
	jnc mode13
	
	; cannot open file (show error message)
	mov dx, fileerror
	call display_text
	jmp exit

	; change to mode 13
mode13:
	mov ah, 0
	mov al, 0x13
	int 0x10


readfile:
	; read from the opened file
	mov cx, 6400		; read 320 bytes at a time.
	mov ax, 0xA000		; set ds to video buffer segment
	mov ds, ax
	mov dx, 0		; start from the top
.again:
	mov ah, 0x3F
	int 0x21		; make the read call

	add dx,6400		; move to the next row

	; check for eof
	cmp ax, 0
	jnz .again

	; wait for key stroke
	mov ah, 0
	int 0x16
	
	call change_to_text_mode
exit:
	; exit to dos
	mov ah, 0x4c
	mov al, 0
	int 0x21

change_to_text_mode:
	push ax
	mov ah, 0
	mov al, 3
	int 0x10
	pop ax
	ret

display_text:
	push ax

	; dos call to display message
	mov ah, 09
	int 0x21
	pop ax
	ret

filename: 	db 'ossplash.bin',0
fileerror: 	db 'Cannot open file.$' 
