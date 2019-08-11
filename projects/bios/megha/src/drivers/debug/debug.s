; Megha Operating System Panic/Debug driver.
; The functions in this file is called by the kernel, drivers or application
; programs.
; Build version: 0.1 (10819)
;
; Initial release: 10th Aug 2019
; 

; Every driver and application programs start at location 0x64
; The above area (0 to 0x63) is for future use, and not used currently.
	ORG 0x64

; The first function in a driver program is a _init function. This function is
; responsible to setup the driver - install into IVT etc. 
_init:
	; install dispatcher into the IVT
	push ax
	push es
	    xor ax, ax 
	    mov es, ax
	    mov [es:0x41 *4], word dispatcher
	    mov [es:0x41 *4 + 2], cs
	pop es
	pop ax

	retf

; Dispatcher is the function that will be installed into the IVT. 
; The function will be identified by a number in BX register.
; Arguments are provided in AX, CX, DX, SI, DI. Return in BX

; Part of the function is to 
; 1. Save the caller DS into another register and set DS to the value in CS
; 2. Call the appropriate function and
; 3. Restore the DS to the same value as it was when dispatcher was called.
dispatcher:
	    pusha		; Pushes AX, BX, CX, DX, SP, BP, SI, DI
	    push ds
	    push es
		push bx

		    ; Save Caller DS into ES
		    mov bx, ds
		    mov es, bx

		    ; DS = CS
		    mov bx, cs
		    mov ds, bx

		pop bx	; restore bx

	    ; Call the appropriate function based on value in BX
	    ;
	    ; Note that we cannot use call [calltable + bx *2] in real mode.
	    ; Effective address do not have a scale in real mode, so we
	    ; multiply by the 'scale' manually in the instruction below.
	    shl bx, 1			; multiply BX by 2
	    call [calltable + bx]	; call the appropriate routine.

	    pop es
	    pop ds
	    popa
	iret

; Copies one character with attribute in the VBA memory.
; This function also maintains the current offset in the VGA memory
; Input: BL - Character to print
;        BH - Attribute
putchar:
	    push es
	    push bx
	    push di

		; setup the segment (ES), and offset (DI) value.
	    	push bx
		    mov bx, 0xb800
		    mov es, bx
		pop bx
		mov di, [vga_offset]

		; print out the character and attribute byte
		mov [es:di], bl
		mov [es:di + 1], bh
		
		; We increment the offset variable
		add [vga_offset], byte 2
	    pop di
	    pop bx
	    pop es
	ret

; Clears the vga memory, and resets the vga_offset value to zero
; Input: none 
; Output: none
clear:
	    push cx
	    push ax
	    push di
	    push es
	    	mov ax, 0xb800
		mov es, ax
		mov di, 0

		mov ax, 0x0
		mov cx, 2000		; 80 words/row, 25 rows	
		cld
		rep stosw

		mov [vga_offset], word 0
            pop es
	    pop di
	    pop ax
	    pop cx
	ret
; Copies a zascii stirng of bytes to VGA memory.
; Input: Address to print is in ES:AX
; Output: none
printstr:
	push si
	push bx

	    mov si, ax
	    mov bh, 0xF
.rep:
	    mov bl, [es:si]
	    cmp bl, 0
	    je .end
	    call putchar
	    inc si
	    jmp .rep
.end:
	pop bx
	pop si
	ret		
; Prints out hexadecimal representation of a 16 bit number.
; Input: AX
; Output: None
;
; We need to save ES registers, as we it contains the DS of the caller.
; All the other registers are taken care of in the dispatcher.
printhex:
	    push es
	    push cx
	    push bx
	    push ax

		mov cx, 4		; we are doing 16 bits, so 4 hex chars
.rep:
		mov bx, ax		; just save the input
		shr bx, 12		; left most nibble to the right most
		mov bl, [.hexchars + bx]; Get the hex character
		mov bh, 0xF		; print the character in WHITE
		call putchar		; prints the character and incremnts
					; the offset in vga memory
		shl ax, 4		; Position the next nibble
		loop .rep
		
	    pop ax
	    pop bx
	    pop cx
	    pop es
	ret
.hexchars: db "0123456789ABCDEF"

section .data
calltable: dw	printhex, printstr, clear
vga_offset: dw  0
