
org 100H

section .data
loadingmsg: db "Hello planet Mars",0

section .text
	; clear the segment registers
	;mov ax,0h
	;mov ds,ax
	;mov cs,ax
	;mov es,ax

	;call bios INT 10H/0EH to print one character at a time.
	cld					;clear Direction flag (DF), so that si is incremented.
	mov si,loadingmsg
	call printString
	jmp .end

	;dos exit
.end:
	mov ah,4Ch
	mov al,0h
	int 21h

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
