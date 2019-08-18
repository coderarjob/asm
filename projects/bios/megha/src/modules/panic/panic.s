
; Megha Operating System Panic Message Output
; Version: 0.1 (180819)
;
; Displays the message and halts the computer

; Every module in MOS starts at location 0x64.
	ORG 0x64

_init:
	pusha
	push es
	    ; Register the panic routine in IVT
	    xor bx,bx
	    mov es, bx

	    mov [es:0x42*4],word panic
	    mov [es:0x42*4+2],cs
	pop es
	popa

	; We need to do Far Return to get back to the loader
	retf

; Displays zascii string on the screen.
; Input: DS:SI - Source ZASCII string to be printed.
; Output: None
print_string:
	lodsb
	cmp al, 0
	je .end

	mov [es:bx], al
	mov [es:bx+1],byte 0xF	; Print in RED

	add bx, 2
	jmp print_string
.end:
	ret

; Displays a message on the screen and halts the computer
; The Message is printed in the 4th line of the screen.
;
; Input: DS:SI - Source ZASCII string to be printed.
; Output: None
panic:
	push si
	push ds
	    mov bx, cs
	    mov ds, bx

	    mov bx, 0xb800
	    mov es, bx
	    mov bx, 0x1E0

	    mov si, panic_msg
	    call print_string
	pop ds
	pop si
	
	call print_string

	; This routine do not return
	jmp $

; ============== DATA SEGMENT =================
panic_msg: db "  --- > kernel panic: ",0
