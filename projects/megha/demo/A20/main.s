; Tests if the A20 line is enabled. 
; Enables the A20 line with various methods.

	org 0x7c00

; ---------------------------------------------------------------------------
; BIOS PARAMETER BLOCK
; ---------------------------------------------------------------------------
%include "../bpb.s"
; ---------------------------------------------------------------------------
; JUMP LOCATION AFTER BPB
; ---------------------------------------------------------------------------
boot_main:
	cli
	call test_a20
	call print_a20_status
	jc .enabled

	; 1st try - BIOS
	call enable_a20_bios
	call test_a20
	call print_a20_status
	jc .enabled

	; 2nd try - 8042
	call enable_a20_8042
	call test_a20
	call print_a20_status
	jc .enabled

	; 3rd try - Fast A20
	call enable_a20_fast
	call test_a20
	call print_a20_status
	jc .enabled

	; Fatal error - A20 line could not be enabled.
.failed:
.enabled:
	sti
	jmp $

; Enables A20 line using 8042 Keyboard controller
enable_a20_8042:
	push ax

	xor ax, ax

	; Disables the keyboard
	call wait_kb_input_empty
	mov al, 0xAD
	out 0x64, al

	; Read the controller output port
	call wait_kb_input_empty
	mov al, 0xD0
	out 0x64, al

	call wait_kb_output_full
	in al, 0x60
	push ax

	; Write to Controller output port
	call wait_kb_input_empty
	mov al, 0xD1
	out 0x64, al

	; Enable the A20 line
	pop ax
	or ax, 2

	call wait_kb_input_empty
	out 0x60, al

	; Enable the Keyboard 
	mov al, 0xAE
	out 0x64, al

	pop ax
	ret

; This routine must be called before reading from port 0x60
wait_kb_output_full:
	push ax	
.again:
	in al, 0x64
	test al, 1
	jz .again		; 1st bit must be 1, Output buffer is full.
	pop ax			; Z Flag is not set. Output buffer is full.
	ret

; This routine must be called before writing to port 0x60 or 0x64
wait_kb_input_empty:
	push ax
.again:
	in al, 0x64
	test al, 2
	jnz .again		; 2nd bit must be 0, Input buffer must be empty.
	pop ax			; Z flag is set. Input buffer is empty.
	ret

; Enables A20 line using FAST A20 method
enable_a20_fast:
	push ax
		in al, 0x92
		or al, 2
		out 0x92, al
	pop ax
	ret

; Enables A20 line using BIOS INT 15 routine
enable_a20_bios:
	push ax
		mov ax, 0x2401
		int 0x15
	pop ax
	ret

; A20 status is printed on screen. If A20 is enabled, 1 is printed, else a 0 is
; printed.
; Input:
;	Carry Flag - Status
; Output:
;	None
print_a20_status:
	pusha
	pushf
		mov bx, 0xB800
		mov es, bx

		mov bx, [.line]

		jnc .a20_disabled
.a20_enabled:
		mov al, '1'		; 1 will be printed.
		jmp .end
.a20_disabled:
		mov al, '0'		; 0 will be printed
.end:
		; Print the character
		mov ah, 0xF
		mov [es:bx],ax

		; Increment two bytes, this is the location where next character will
		; be printed.
		add word [.line], 2
	popf
	popa
	ret
.line: resw 1

; We will write one byte at location 0:500 and another at FFFF:510. If the two
; bytes remain distinct, A20 line is enabled. If byte at FFFF:510 and 0:500
; becomes same, A20 line is disabled (memory location has wrapped around)
; Input:
;	None
; Output:
;	Carry flag - 0 (disabled), 1 (enabled)
test_a20:
	push es
	push ds

	; Setup segment registers
	mov ax, 0xFFFF
	mov es, ax

	xor ax, ax
	mov ds, ax

	; Save the words at the two locations
	push word [es:0x510]
	push word [ds:0x500]

	; Write bytes to the two locations
	mov [ds:0x500],byte 1
	mov [es:0x510],byte 0

	; Compare byte at location 0:0x500. If it is 1, then a20 is enabled.
	cmp byte [ds:0x500], 1
	je .a20_enabled

.a20_disabled:
	clc
	jmp .end
.a20_enabled:
	stc
.end:
	; Restore bytes at the locations
	pop word [ds:0x500]
	pop word [es:0x510]

	;Restore registers
	pop ds
	pop es
	ret

; ---------------------------------------------------------------------------
; END OF BOOT LOADER
; ---------------------------------------------------------------------------
	 times 510 - ($ - $$) db 0
	 dw 0xAA55
; ---------------------------------------------------------------------------
