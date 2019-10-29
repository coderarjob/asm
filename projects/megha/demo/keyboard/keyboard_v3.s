; DOS program that enquires keyboard controller about the status of its input
; buffer.

	org 0x64
	;org 0x100

_init:
	; clear the screen
	mov ah, 0
	mov al, 3
	int 0x10

	push cs
	pop ds

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

.check:	
	; Check if any key was pressed
	cmp [dirty], byte 1
	jne .check

	; Get the scan code
	xor dx, dx
	mov dl, [key.scancode]
	;call printhex
	
	; If ESC was pressed, we exit
	cmp dl, 1
	je .end

	; Get the key code
	mov dl, [key.keycode]
	call printhex

	; Get flags
	mov dl, [key.flags]
	;call printhex

	; Get leds
	mov dl, [key.leds]
	;call printhex

	; Rest the dirty flag
	mov [dirty], byte 0
	jmp .check

.end:
	; restore original ISR
	mov ax, [old_kb_int_offset]
	mov [gs:9*4], ax
	mov ax, [old_kb_int_seg]
	mov [gs:9*4+2],ax

	; exit dos
	retf
	;mov ah, 0x4c
	;int 0x21

kb_interrupt:
	pusha
		; Read the Scan code from the keyboard
		in al, 0x60				

		; ----------------------------------------
		; The return code could also be 0xFA or 0xFE
		; We ignore them for now.
		; ----------------------------------------
		cmp al, 0xFA
		je .endb

		cmp al, 0xFE
		je .endb

		; ----------------------------------------
		; Check if Extended key
		; ----------------------------------------
		cmp al, 0xE0
		jne .n1

		or [key.flags], byte EXTENDED	; SET EXTENDED FLAG
		jmp .endb						; We do not add 0xE0 to the output and
										; A second interrupt will have the scan
										; code of the Extended key.

.n1:
		; ----------------------------------------
		; We Save the Scan code
		; ----------------------------------------
		mov [key.scancode], al

		; ----------------------------------------
		; Check is key is released or pressed
		; We set the PRESSED flag and get the MAKE Code from 
		; the currently available BREAK code, by 
		; ANDING by 0x7F or ~0x80
		; ----------------------------------------
		test al, 0x80		; ANDing in order to check for break codes.
		jz .n1a				; Not a break code, continue

		and al, ~0x80
		and [key.flags], byte ~PRESSED	; CLEAR PRESSED Flag
		jmp .n2
.n1a:
		or [key.flags], byte PRESSED	; SET PRESSED Flag
.n2:
		; ----------------------------------------
		; We save the Key code
		; ----------------------------------------
		xor bx, bx
		mov bl, al
		mov ah, [key_codes + bx]
		mov [key.keycode], ah

		; ----------------------------------------
		; Check for SHIFT key press
		; ----------------------------------------

		; --- Check for Left Shift Key
		cmp al, key_codes.LSHIFT
		je .n2a					; It is Left Shift Key

		; --- Check for Right Shift key
		cmp al, key_codes.RSHIFT
		jne .n3					; Neither of the SHIFT keys
.n2a:
		; --- Check if pressed or released
		test [key.flags], byte PRESSED	
		jz .n2_rel			; SHIFT key is being released not pressed.

		or [key.flags], byte SHIFT		; SET SHIFT Flag
		jmp .end
.n2_rel:
		and [key.flags], byte ~SHIFT	; CLEAR SHIFT Flag
		jmp .end

.n3:
		; ----------------------------------------
		; Check for CONTROL key press
		; ----------------------------------------
		
		cmp al, key_codes.CTRL
		jne .n4				; Not a CONTROL key

		; --- Check if key is being pressed or released.
		test [key.flags], byte PRESSED	
		jz .n3_rel				; CONTROL key is being released 

		or [key.flags], byte CTRL	; SET CONTROL Flag
		jmp .end
.n3_rel:
		and [key.flags], byte ~CTRL	; CLEAR CONTROL Flag
		jmp .end

.n4:
		; ----------------------------------------
		; Check for ALT key press
		; ----------------------------------------
		
		cmp al, key_codes.ALT
		jne .n5				; Not a ALT key

		; --- Check if key is being pressed or released.
		test [key.flags], byte PRESSED	
		jz .n4_rel			; Key is being released 

		or [key.flags], byte ALT		; SET ALT Flag
		jmp .end
.n4_rel:
		and [key.flags], byte ~ALT		; CLEAR ALT Flag
		jmp .end

.n5:
		; ----------------------------------------
		; Check for CAPS LOCK key press
		; ----------------------------------------

		cmp al, key_codes.CAPS
		jne .n6

		xor bx, bx
		mov bl, [key.caps_state]
		imul bx, 2
		jmp [.jtable_caps + bx]

.caps_case0:
		test [key.flags], byte PRESSED
		jz .end

		; --- key is pressed, we engage the CAPS Lock and LEDs
		mov [key.caps_state], byte 1
		or [key.flags], byte CAPS
		or [key.leds], byte CAPS_LED
		jmp .end
.caps_case1:
		test [key.flags], byte PRESSED
		jnz .end
		
		; --- Key is released, we move the state
		mov [key.caps_state], byte 2
		jmp .end
.caps_case2:
		test [key.flags], byte PRESSED
		jz .end

		; --- key is pressed, we de-engage the CAPS Lock and LEDs
		mov [key.caps_state], byte 3
		and [key.flags], byte ~CAPS
		and [key.leds], byte ~CAPS_LED
		jmp .end
.caps_case3:
		test [key.flags], byte PRESSED
		jnz .end
		
		; --- Key is released, we move the state
		mov [key.caps_state], byte 0
		jmp .end
.n6:
		; ----------------------------------------
		; Check for NUM LOCK key press
		; ----------------------------------------

		cmp al, key_codes.NUM
		jne .n7							; Not the NUM Lock

		xor bx, bx
		mov bl, [key.nums_state]
		imul bx, 2
		jmp [.jtable_nums + bx]

.nums_case0:
		test [key.flags], byte PRESSED
		jz .end

		; --- key is pressed, we engage the CAPS Lock and LEDs
		mov [key.nums_state], byte 1
		or [key.flags], byte NUM
		or [key.leds], byte NUM_LED
		jmp .end
.nums_case1:
		test [key.flags], byte PRESSED
		jnz .end
		
		; --- Key is released, we move the state
		mov [key.nums_state], byte 2
		jmp .end
.nums_case2:
		test [key.flags], byte PRESSED
		jz .end

		; --- key is pressed, we de-engage the CAPS Lock and LEDs
		mov [key.nums_state], byte 3
		and [key.flags], byte ~NUM
		and [key.leds], byte ~NUM_LED
		jmp .end
.nums_case3:
		test [key.flags], byte PRESSED
		jnz .end
		
		; --- Key is released, we move the state
		mov [key.nums_state], byte 0
		jmp .end
.n7:
		; ----------------------------------------
		; Check for SCROLL LOCK key press
		; ----------------------------------------

		cmp al, key_codes.SCROLL_LOCK
		jne .end

		mov bx, [key.scroll_state]
		imul bx, 2
		jmp [.jtable_scroll + bx]

.scroll_case0:
		test [key.flags], byte PRESSED
		jz .end

		; --- key is pressed, we engage the SCROLL Lock and LEDs
		mov [key.scroll_state], byte 1
		or [key.flags], byte SCROLL_LOCK
		or [key.leds], byte SCROLL_LED
		jmp .end
.scroll_case1:
		test [key.flags], byte PRESSED
		jnz .end
		
		; --- Key is released, we move the state
		mov [key.scroll_state], byte 2
		jmp .end
.scroll_case2:
		test [key.flags], byte PRESSED
		jz .end

		; --- key is pressed, we de-engage the SCROLL Lock and LEDs
		mov [key.scroll_state], byte 3
		and [key.flags], byte ~SCROLL_LOCK
		and [key.leds], byte ~SCROLL_LED
		jmp .end
.scroll_case3:
		test [key.flags], byte PRESSED
		jnz .end
		
		; --- Key is released, we move the state
		mov [key.scroll_state], byte 0
		jmp .end

.extended_get_next_key:
		; Note that we do not want to add 0xE0 into the queue, so we skip the
		; below instruction
		jmp .endb

.end:
		; We add to the queue here
		mov [dirty], byte 1

		; CLEAR EXTENDED Flag
		; EXTENDED Flag is just an indecation that the current keycode is part
		; of an Extended keybord or not. It is not marked continously through
		; multiple keypresses like the SHIFT or CONTROL key.
		and [key.flags], byte ~EXTENDED

		; Set the LEDS
		call wait_kbd
		mov al, 0xED
		out 0x60, al
		call wait_kbd
		mov al, [key.leds]
		out 0x60, al
.endb:
		; send a EOI to PIC
		mov al, 0x20
		out 0x20, al

	popa
	iret
.jtable_nums: dw .nums_case0, .nums_case1, .nums_case2, .nums_case3
.jtable_caps: dw .caps_case0, .caps_case1, .caps_case2, .caps_case3
.jtable_scroll: dw .scroll_case0, .scroll_case1, .scroll_case2, .scroll_case3

wait_kbd:
	push ax
.check:
		in al, 0x64
		test al, 0x2
		jnz .check
	pop ax
	ret

; Prints 16 bit hex number
; Input: DX
printhex:
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
		shr si, 12
		mov ax, [.hexchars+si]

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
.hexchars: db "0123456789ABCDEF"
cpos: dw 0

; Prints a ASCII character to screen buffer
; Input:
;	DX = Character
printchar:
	push es
	pusha

		; setup the segment registers
		mov bx, 0xb800
		mov gs,bx
		mov bx, [cpos]	; load the current memory offset to write to.
		; the below loop will run 4 times.

		mov [gs:bx], dl
		mov [gs:bx+1],byte 0xF
		add word [cpos], 2
	popa
	pop es
	ret

NUM: EQU 0x1
CAPS: EQU 0x2
SHIFT: EQU 0x4
CTRL: EQU 0x8
ALT: EQU 0x10
SCROLL_LOCK: EQU 0x20
EXTENDED: EQU 0x40
PRESSED: EQU 0x80

SCROLL_LED: EQU 0x1
NUM_LED: EQU 0x2
CAPS_LED: EQU 0x4

old_kb_int_offset: dw 1
old_kb_int_seg: dw 1
dirty: db 0

key:
	.flags db 0
	.scancode db 0
	.keycode db 0
	.leds db 0
	.caps_state db 0
	.nums_state db 0
	.scroll_state db 0

; -----------------------------------------------------------------
; Scan code to Key code map
; Legend: 
;		  Numbers      : 0		   --> 0xB
;						 1 - 9     --> 0x2 0xA
;		  Num KeyPad   : 0 - 4     --> 0x10 to 0x14
;   				   : 5         --> 0x6
; 					   : 6 - 9	   --> 0x16 - 0x19
;		  Arrow Keys   : Down      --> 0x12
;					   : Left      --> 0x14
;					   : Right     --> 0x16
;					   : Up        --> 0x18
;         Characters   : A - Z     --> 0x41 to 0x5A
;		  Function keys: F1 to F10 --> 0x61 to 0x6C
;		  Delete Key   :           --> 0x6D
; -----------------------------------------------------------------
key_codes:
	db 0,1,2,3,4,5,6,7									; 0x7
	db 8, 9,0xA,0xB,'-','=',0xE			 				; 0xE
	db 0xF, 'Q', 'W', 'E', 'R', 'T'						; 0x14
	db 'Y', 'U', 'I', 'O', 'P', '['						; 0x1A
	db ']',0x1C, 0x1D,'A','S','D','F'					; 0x21
	db 'G','H','J','K','L',';', "'", '`'				; 0x29
	db 0x2A, '\', 'Z', 'X', 'C', 'V', 'B'				; 0x30
	db 'N', 'M', ',', '.', '/', 0x36, 0x37				; 0x37
	db 0x38, ' ', 0x3A, 0x61, 0x62, 0x63				; 0x3D
	db 0x64, 0x65, 0x66, 0x67, 0x68, 0x69				; 0x43
	db 0x6A, 0x45, 0x46, 0x17, 0x18, 0x19, '-'			; 0x4A
	db 0x14, 0x15, 0x16, '+', 0x11, 0x12, 0x13, 0x10    ; 0x52
	db 0x6D,0x54,0x55,0x56,0x6B,0x6C					; 0x58

.LSHIFT: EQU 0x2A
.RSHIFT: EQU 0x36
.CAPS: EQU 0x3A
.ALT: EQU 0x38
.CTRL: EQU 0x1D
.NUM: EQU 0x45
.SCROLL_LOCK: EQU 0x46

; -----------------------------------------------------------------
; Key code to ASCII Mapping
;
; Key codes with combinations of SHIFT key and CAPS lock key and NUM lock key
; are mapped to get corresponding ASCII codes.
;
;No Change Keys: 
;	BackSpace (0x8), Tab (0x9), Enter (0x10), Left Control (0x1D),
;	ESC (0x1), Left Shift (0x2A), Right Shift (0x36), Left Alt (0x38), 
;	CapsLock (0x3A), F1 (0x61), ... F12 (0x6C), NUM Lock (0x45), 
;	Scroll Lock (0x46), Delete (0x6D), Extended Up Arrow (0x18), Extended Left
;	Arrow (0x14), Extended Right Arrow (0x16), Extended Down Arrow (0x12)
;
;Change Using Shift:
;	1 (0x2) ... 9 (0xA), 0 (0xB), - (0x2D), = (0x3D), A (0x41) ... Z (0x5A), 
;	[ (0x5B), ] (0x5D), ; (0x3B), ' (0x27), ` (0x60), \ (0x5C), Comma (0x2C), 
;	.  (0x2E), / (0x2F)
;
;Change Using Caps Lock:
;	A (0x41) .... Z (0x5A)
;
;Change Using Num Lock:
;	Non Extended Numeric Key Pad: 0 (0x10) ... 9 (0x19)
; -----------------------------------------------------------------

ascii:		; Normal, Shifted, CAPS Lock
