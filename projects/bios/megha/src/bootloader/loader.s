; Megha OS Loader
; Version: 0.01

	; ******************************************************
	; MACRO BLOCK
	; ******************************************************

	%macro printString 1
		push si
		mov si, %1
		int 0x31
		pop si
	%endmacro

	; ******************************************************
	; MAIN BLOCK
	; ******************************************************

	; switch to 0x13 mode
	mov ah, 0
	mov al, 0x13	; 256 color palette 320*200 vga
	int 0x10

	mov ax, 0xA000
	mov bx, 0
	mov cx, ds
	mov dx, splashfile

	push ds
	push es
	push fs
	push gs
	push ax
	mov ax, 0
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	pop ax

	int 0x30

	pop gs
	pop fs
	pop es
	pop ds

	cmp ax, 0
	jne exit
failed_file_not_found:
	printString file_not_found_string
exit:
	jmp $
	
splashfile: db 'OSSPLASHBIN'
welcome_msg: db "Megha Operating system loader",10,13,
	     db "=============================",0
file_not_found_string: db "File is not found",0


