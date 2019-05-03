; Dos application that uses BIOS Wait (int 15, ah = 86h) for a delay of 1
; second

;	org 0x100
	org 0x7C00
	%include "../bpb.s"

boot_main:

	; delay routine
	mov bx, 5
.rep:
	mov cx, 0xF
	mov dx, 0xA0
	mov ah, 0x86
	int 0x15
	; print elapsed time
	mov dx, bx
	mov cx, bx
	mov bx, 6
	sub bx, cx
	add bx, 0x30
	mov al,bl
	call printc
	mov bx, dx
	; decrement and loop
	dec bx
	jnz .rep

	jmp $

	;exit dos
	;mov ah, 0x4c
	;mov al, 0
	;int 0x21

printc:
	push bx
	mov ah, 0xE
	mov bx, 0
	int 0x10
	pop ax
	ret

	times 510 - ($-$$) db 0
	dw 0xAA55
