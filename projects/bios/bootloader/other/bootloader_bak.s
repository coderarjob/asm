
section .text
	; clear the segment registers
	; bios loads the first sector from the boot device to memory at location
	; 0x7C00.
	; 0x7C00 location lies at the start of the segment 0x7C00/0x10 = 0x7C0
	; This is the number that new will put into the stack and data segment
	; registers.

	; we setup the stack location
	; Stack will be 1k in size.

	; way 1: code, data, stack in the same section
	mov ax,0x7C0 
	mov ds,ax
	mov ss,ax
	mov sp,0x5FF 		; 512 + 1024 = 1536 (or 0x600)

	;call bios INT 10H/0EH to print one character at a time.
	cld					;clear Direction flag (DF), so that si is incremented.
	mov si,versonmsg
	call printString

	mov si,pressanykeymsg
	call printString
	
	;wait for a character
	mov ah,00h
	int 16h

	; go into graphics mode
	mov ah,00h
	mov al,13h		; 320 x 200
	int 10h
	
	; print a string in graphics mode
	mov ah,13h			; write text in graphics mode.
	mov al,0h
	mov bx,3h
	mov cx,msglen
	mov dh,10	; 10th row
	mov dl,0	; 0th column
	mov si,ds
	mov es,si
	mov bp,bootingmsg
	int 10h

	;halt
	jmp $	; or hlt (hlt caused virtual box to give a critical error message)

printString:
	push ax
	push bx
	mov ah,0Eh		; bios call to display character
	mov bx,0h		; 0th page, and border byte (could be anything)
.rep:
	lodsb
	cmp al,0h
	jz .end
	int 10h
	jmp .rep
.end:
	pop bx
	pop ax
	ret


versonmsg: db "Basic boot loader by Arjob", 10, 13, "Version: 0.1c",0
pressanykeymsg: db "Press any key to start booting...",0

bootingmsg:	db "Please wait while your maching is booting...",0
msglen: equ $-bootingmsg

	times 510 - ($-$$) db 0
	dw 0xAA55
