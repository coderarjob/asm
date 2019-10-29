; DOS program that enquires keyboard controller about the status of its input
; buffer.

;	org 0x100
	org 0x7c00
	%include "../bpb.s"

scan_code: resb 1
is_dirty: db 0

old_kb_int_offset: dw 1
old_kb_int_seg: dw 1

boot_main:
	; clear the screen
	mov ah, 0
	mov al, 3
	int 0x10

	; install the keyboard interrupt
	xor ax, ax
	mov gs, ax

	; save original ISR address
	mov ax, [gs:9*4]
	mov [old_kb_int_offset],ax
	mov ax, [gs:9*4+2]
	mov [old_kb_int_seg], ax


	; install our ISR in IVT
	mov [gs:9*4], word kb_interrupt
	mov [gs:9*4+2],cs

.check:	cmp [is_dirty],byte 1
	jne .check

	mov [is_dirty], byte 0 	; clear the flag
	cmp [scan_code],byte 1	; esc key
	je .end

	xor dx, dx
	mov dl, [scan_code];
	call printhex
	jmp .check
.end:
	; restore original ISR
	mov ax, [old_kb_int_offset]
	mov [gs:9*4], ax
	mov ax, [old_kb_int_seg]
	mov [gs:9*4+2],ax

	; exit dos
	jmp $
	;mov ah, 0x4c
	;int 0x21

kb_interrupt:
	pusha
.again:
	in al, 0x60	; al has the scan code
	mov [scan_code], al	; save the scan code to be used later
	mov [is_dirty], byte 1	; 1 means that there is new char

	; send a EOI to PIC
	mov al, 0x20
	out 0x20, al

	popa
	iret

; Waits for the keyboard input buffer to be empty
; because if it is full, we cannot give more commands here
kb_wait:
	push ax
.loop: in al, 0x64
	test al, 0x2
	jnz .loop
	pop ax
	ret

; Prints 16 bit hex number
; Input: DX
cpos: dw 0
printhex:
.number	equ 4

	push gs
	pusha	; push all general purpose registers

	; setup the segment registers
	mov bx, 0xb800
	mov gs,bx
	mov bx, [cpos]	; load the current memory offset to write to.

	; the below loop will run 4 times.
	mov cx, 4
.again:
	mov si, dx
	and si, 0xF000
	shr si, 12

	mov ax, [hexchars+si]
	mov [gs:bx],al
	mov [gs:bx+1],byte 0xE
	
	add bx,2
	shl dx,4
	loop .again

	add bx, 2	; leave a blank
	mov [cpos],bx
	popa
	pop gs
	ret

hexchars: db "0123456789ABCDEF"

	times 510 - ($-$$) db 0
	dw 0xAA55

