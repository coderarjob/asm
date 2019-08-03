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

	; Load  'splashfile' into 0xA000:0 location
	mov ax, 0xA000
	mov bx, 0
	mov dx, splashfile
	int 0x30

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


