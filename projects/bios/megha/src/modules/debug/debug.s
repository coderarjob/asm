; Megha Operating System Panic/Debug module.
; The functions in this file is called by the kernel, drivers or application
; programs.
; Build version: 0.1 (100819)
;
; Initial release: 10th Aug 2019
; 

; Every driver and application programs start at location 0x64
; The above area (0 to 0x63) is for future use, and not used currently.
	ORG 0x64

; The first function in a driver program is a _init function. This function is
; responsible for setting up the driver - install routines into IVT etc. 
_init:
	pusha

	    ; Add various function to the despatcher

	    ;printhex
	    mov bx, DS_ADD_ROUTINE	; call AddRoutine function
	    mov al, 0xFF
	    mov cx, cs
	    mov dx, printhex
	    int 0x41

	    ;printstr
	    mov bx, DS_ADD_ROUTINE	; call AddRoutine function
	    mov al, DB_PRINTSTR
	    mov cx, cs
	    mov dx, printstr
	    int 0x41

	    ;clear
	    mov bx, DS_ADD_ROUTINE	; call AddRoutine function
	    mov al, DB_CLEARSCR
	    mov cx, cs
	    mov dx, clear
	    int 0x41
	
	popa

	; RETF is a must to be able to return to the loader.
	retf

; Prints the hex representation of bytes in memory location
; Input: AX:DX - Location of the memory location
;        CX    - Number of bytes to show
; Output: none
hexdump:
	mov bx, cx
	ret
.hexdump_template: db "xxxx:xxxx    01 02 03 04 05 06 07 08"

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
	retf

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
	retf		
; Prints out hexadecimal representation of a 16/8 bit number.
; Input: AX -> Number
;        CX -> Number of bits to show in the hex display.
;              16 - to see 16 bit hex
;              8  - to see 8 bit hex (will show only AL)
;	       Note: 0 < CX < 16 and CX is divisible by 4
; Output: None
;
; We need to save ES registers, as we it contains the DS of the caller.
; All the other registers are taken care of in the dispatcher.
printhex:
	    push es
	    push cx
	    push bx
	    push ax

		; Number of times the below loop need to loop
		; Number of itterations = CX/4
		mov bx, cx
		shr bx, 2
	
		; We Shift the number so many times so that the required bits
		; come to the extreme left.
		; Number of left shits = (16 - CX) or -(CX - 16)
		sub cx, 16
		neg cx
		shl ax, cl

		; Load the number of loop itteration into CX
		mov cx, bx		; we are doing 16 bits, so 4 hex chars
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
	retf
.hexchars: db "0123456789ABCDEF"

section .data
vga_offset: dw  0

; ======================== INCLUDE FILES ===================
%include "../include/mos.inc"
