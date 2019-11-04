; DOS program that enquires keyboard controller about the status of its input
; buffer.

	;org 0x64
	org 0x100

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

	mov dl, '@'
	call printchar

.check:	
	; Check if any key was pressed
	cmp [dirty], byte 1
	jne .check

	; -------------------------
	; Rest the dirty flag
	; -------------------------
	mov [dirty], byte 0

	; -------------------------
	; Read ASCII code
	; -------------------------
	xor dx, dx

	cli
		mov al, [key.keycode]
		mov bl, [key.flags]
		mov cl, [key.ascii]
	sti

	cmp al, 1
	je .end

	test bl, byte PRESSED
	jz .check

	mov dl, cl
	cmp dl, 0
	je .check

	call printchar
	;call printhex

	jmp .check

.end:
	; restore original ISR
	mov ax, [old_kb_int_offset]
	mov [gs:9*4], ax
	mov ax, [old_kb_int_seg]
	mov [gs:9*4+2],ax

	; exit dos
	;retf
	mov ah, 0x4c
	int 0x21

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
		
		test [key.flags],byte EXTENDED
		jz .resolve

		; We have an Extended key, so we do a little math to resolve a
		; normalized scancode. 
		; Note: This calculation will change is the we start receiving
		; different scancodes, for example when attaching a new keyboard.

		; The calculation normalizes scan codes for the Effective keys and
		; makes the effective key with the smallest scan code start from 0.
		; The smallest scan code for any effective key (in my current keyboard)
		; is 0x1C or 28.

		; The maximum scan code generated from my computer keyboard is 0x5B or
		; 91 in decimal. So the Scan codes for these Extended keys must be after
		; 91. I have chosen that the effective scan code for the first Extended
		; key should be 100.

		; Normalized position (zero based) = Scan Code - 0x1C
		; Position in the keycodes array = Normalized position + 100

		add bx, 100 - 0x1C
.resolve:
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
		jmp .end_led_modified
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
		jmp .end_led_modified
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
		jmp .end_led_modified
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
		jmp .end_led_modified
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
		jne .end							; Not SCROLL Lock

		mov bx, [key.scroll_state]
		imul bx, 2
		jmp [.jtable_scroll + bx]

.scroll_case0:
		test [key.flags], byte PRESSED
		jz .end								; LED update is not needed.

		; --- key is pressed, we engage the SCROLL Lock and LEDs
		mov [key.scroll_state], byte 1
		or [key.flags], byte SCROLL_LOCK
		or [key.leds], byte SCROLL_LED
		jmp .end_led_modified				; Update LEDs
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
		jmp .end_led_modified
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

.end_led_modified:
		; Set the LEDS
		call wait_kbd
		mov al, 0xED
		out 0x60, al

		call wait_kbd
		mov al, [key.leds]
		out 0x60, al
.end:
		; Get ASCII code for the keycode
		xor bx, bx
		mov bl, [key.keycode]
		mov bl, [modifier_maps + bx]
		shl bx, 1

		call [modifiers_routines + bx]

		;test [key.flags], byte PRESSED
		;jz .cont

		;mov dl, [key.ascii]
		;call printchar

.cont:
		; We add to the queue here
		mov [dirty], byte 1

		; CLEAR EXTENDED Flag
		; EXTENDED Flag is just an indication that the current keycode is part
		; of an Extended keybord or not. It is not marked continously through
		; multiple keypresses like the SHIFT or CONTROL key.
		and [key.flags], byte ~EXTENDED
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
		test al, 0x2		; Check PS/2 input buffer. If full we check again.
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
	push gs
	pusha

		; setup the segment registers
		mov bx, 0xb800
		mov gs,bx
		mov bx, [cpos]	; load the current memory offset to write to.

		mov [gs:bx], dl
		mov [gs:bx+1],byte 0xF
		add word [cpos], 2
	popa
	pop gs
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
	.ascii db 0

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
	db 8, 9,0xA,0xB,0x1D,0x28,0xC			 			; 0xE
	db 0xD, 'Q', 'W', 'E', 'R', 'T'						; 0x14
	db 'Y', 'U', 'I', 'O', 'P', 0x29					; 0x1A
	db 0x2B,0x18, 0x19,'A','S','D','F'					; 0x21
	db 'G','H','J','K','L',0x27, 0x1B, 0x2C				; 0x29
	db 0x1C, 0x2A, 'Z', 'X', 'C', 'V', 'B'				; 0x30
	db 'N', 'M', 0x20, 0x21, 0x22, 0x23, 0x24			; 0x37
	db 0x25, 0x1A, 0x26, 0x2D, 0x2E, 0x2F				; 0x3D
	db 0x30, 0x31, 0x32, 0x33, 0x34, 0x35				; 0x43
	db 0x36, 0x3A, 0x3B, 0x15, 0x16, 0x17, 0x1F			; 0x4A
	db 0x12, 0x13, 0x14, 0x1E, 0xF, 0x10, 0x11, 0xE     ; 0x52
	db 0x39,0,0,0,0x37,0x38,0,0,0,0,0,0,0,0,0,0,0x00	; 0x63
	db 0x64, 0x3C,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ; 0x78
	db 0,0,0,0,0,0,0x3D, 0x3E, 0,0,0,0,0,0,0,0,0,0		; 0x8A
	db 0,0,0,0,0x3F,0x40,0x5B, 0,0x5C,0,0x5D,0,0x5E		; 0x97
	db 0x5F, 0x60, 0x61, 0x62, 0,0,0,0,0,0,0,0x63,0		; 0xA4
	db 0x65												; 0xA5

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
; -----------------------------------------------------------------


; Sets the ASCII Code for the key code.
get_ascii:
.no_modifier_keys:
	push ax
	push bx
		xor bx, bx
		mov bl, [key.keycode]
		jmp .normal
		
.shift_modified_keys:
	push ax
	push bx
.shift_modified_keys_1:
		xor bx, bx
		mov bl, [key.keycode]

		test [key.flags], byte SHIFT		
		jz .normal							; SHIFT is not PRESSED
	
		xor ax, ax
		mov al, [shift + bx]				; SHIFT is PRESSED
		jmp .end

.shift_caps_modified_keys:
	push ax
	push bx
		xor bx, bx
		mov bl, [key.keycode]

		test [key.flags], byte SHIFT
		jz .caps_modified_keys_1				 ; SHIFT is not PRESSED

		test [key.flags], byte CAPS
		jz .shift_modified_keys_1				; JUST SHIFT is PRESSED

		xor ax, ax
		mov al, [shift_caps + bx]			; SHIFT and CAPS are PRESSED.
		jmp .end

.caps_modified_keys:
	push ax
	push bx
.caps_modified_keys_1:
		xor bx, bx
		mov bl, [key.keycode]
	
		test [key.flags], byte CAPS
		jz .normal 							; JUST SHIFT is PRESSED

		xor ax, ax
		mov al, [caps + bx]
		jmp .end

.num_modified_keys:
	push ax
	push bx
		xor bx, bx
		mov bl, [key.keycode]

		test [key.flags],byte NUM
		jz .normal

		xor ax, ax
		mov al, [num + bx]
		jmp .end

.normal:
		xor ax, ax
		mov al, [normal + bx]
.end:
	mov [key.ascii], al
	pop bx
	pop ax
	ret

NONE: EQU 0
M_SHIFT: EQU 1
M_SCAPS: EQU 2
M_CAPS: EQU 3
M_NUM: EQU 4

modifiers_routines: 
dw					get_ascii.no_modifier_keys
dw					get_ascii.shift_modified_keys
dw					get_ascii.shift_caps_modified_keys
dw					get_ascii.caps_modified_keys
dw					get_ascii.num_modified_keys
				
modifier_maps:
		;0/8  1/9   2/A   3/B   4/C   5/D   6/E   7/F 
db		NONE, NONE, M_SHIFT,M_SHIFT,M_SHIFT,M_SHIFT,M_SHIFT,M_SHIFT		; 0x7
db		M_SHIFT,M_SHIFT,M_SHIFT,M_SHIFT,NONE, NONE, M_NUM,  M_NUM		; 0xF
db		M_NUM,  M_NUM,  M_NUM,  M_NUM,  M_NUM,  M_NUM,  M_NUM,  M_NUM	; 0x17
db		NONE, NONE, NONE,M_SHIFT, NONE, M_SHIFT,NONE, NONE				; 0x1F
db		M_SHIFT,M_SHIFT,M_SHIFT,NONE, NONE, NONE, NONE, M_SHIFT			; 0x27
db		M_SHIFT,M_SHIFT,M_SHIFT,M_SHIFT,M_SHIFT,NONE, NONE, NONE		; 0x2F
db		NONE, NONE, NONE, NONE, NONE, NONE, NONE, NONE					; 0x37
db		NONE, NONE, NONE, NONE, NONE, NONE, NONE, NONE					; 0x3F 
db		NONE,M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS	; 0x47
db		M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS ; 0x4F
db		M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS,M_SCAPS ; 0x57
db		M_SCAPS,M_SCAPS,M_SCAPS, NONE, NONE, NONE, NONE, NONE			; 0x5F
db		NONE, NONE, NONE, NONE, NONE, NONE								; 0x65

normal:		
			;0/8  1/9   2/A   3/B   4/C   5/D   6/E   7/F 
db			0x00, 0x1B ,'123456'								; 0x7
db			'7890'                  , 0x00, 0x00, 0x00, 0x00	; 0xF
db			0x00, 0x00, 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x17
db			0xA , 0x00, ' ', "'" 	, 0x00, '-' ,  '+',  '-'	; 0x1F 
db			',' , '.' , '/' , 0x00  , '*' , 0x00, 0x00, ';'		; 0x27
db			'=[\]`'    					  , 0x00, 0x00, 0x00	; 0x2F
db			0x00, 0x00, 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x37
db			0x00, '.' , 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x3F
db			0x00, "abcdefghijklmnopqrstuvwxyz"					; 0x5A
db							  0x00  , 0x00, 0x00, 0x00, 0x00	; 0x5F
db			0x00, 0x00, 0x00, 0x00  , 0xA , 0x00				; 0x65

shift:		
			;0/8  1/9   2/A   3/B   4/C   5/D   6/E   7/F 
db			0x00, 0x1B ,'!@#$%^'								; 0x7
db			'&*()'                  , 0x00, 0x00, 0x61, 0x5E	; 0xF
db			0x5F, 0x60, 0x5C, 0x00  , 0x5D, 0x3F, 0x40, 0x5B	; 0x17
db			0xA , 0x00, 0x20, '"' 	, 0x00, '_' ,  '+',  '-'	; 0x1F 
db			'<' , '>' , '?' , 0x00  , '*' , 0x00, 0x00, ':'		; 0x27
db			'+{|}~'    					  , 0x00, 0x00, 0x00	; 0x2F
db			0x00, 0x00, 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x37
db			0x00, '.' , 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x3F
db			0x00, "ABCDEFGHIJKLMNOPQRSTUVWXYZ"					; 0x5A
db							  0x00  , 0x00, 0x00, 0x00, 0x00	; 0x5F
db			0x00, 0x00, 0x00, 0x00  , 0xA , 0x00				; 0x65

caps:		
			;0/8  1/9   2/A   3/B   4/C   5/D   6/E   7/F 
db			0x00, 0x1B ,'123456'								; 0x7
db			'7890'                  , 0x00, 0x00, 0x61, 0x5E	; 0xF
db			0x5F, 0x60, 0x5C, 0x00  , 0x5D, 0x3F, 0x40, 0x5B	; 0x17
db			0xA , 0x00, 0x20, "'" 	, 0x00, '-' ,  '+',  '-'	; 0x1F 
db			',' , '.' , '/' , 0x00  , '*' , 0x00, 0x00, ';'		; 0x27
db			'=[\]`'    					  , 0x00, 0x00, 0x00	; 0x2F
db			0x00, 0x00, 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x37
db			0x00, '.' , 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x3F
db			0x00, "ABCDEFGHIJKLMNOPQRSTUVWXYZ"					; 0x5A
db							  0x00  , 0x00, 0x00, 0x00, 0x00	; 0x5F
db			0x00, 0x00, 0x00, 0x00  , 0xA , 0x00				; 0x65

shift_caps:		
			;0/8  1/9   2/A   3/B   4/C   5/D   6/E   7/F 
db			0x00, 0x1B ,'!@#$%^'								; 0x7
db			'&*()'                  , 0x00, 0x00, 0x61, 0x5E	; 0xF
db			0x5F, 0x60, 0x5C, 0x00  , 0x5D, 0x3F, 0x40, 0x5B	; 0x17
db			0xA , 0x00, 0x20, '"' 	, 0x00, '_' ,  '+',  '-'	; 0x1F 
db			'<' , '>' , '?' , 0x00  , '*' , 0x00, 0x00, ':'		; 0x27
db			'+{|}~'    					  , 0x00, 0x00, 0x00	; 0x2F
db			0x00, 0x00, 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x37
db			0x00, '.' , 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x3F
db			0x00, "abcdefghijklmnopqrstuvwxyz"					; 0x5A
db							  0x00  , 0x00, 0x00, 0x00, 0x00	; 0x5F
db			0x00, 0x00, 0x00, 0x00  , 0xA , 0x00				; 0x65

num:		
			;0/8  1/9   2/A   3/B     4/C    5/D   6/E   7/F 
db			0x00, 0x1B ,'123456'								; 0x7
db			'7890'                  , 0x00, 0x00, '0123456789'	; 0x17
db			0xA , 0x00, 0x20, "'" 	, 0x00, '-' ,  '+',  '-'	; 0x1F 
db			',' , '.' , '/' , 0x00  , '*' , 0x00, 0x00, ';'		; 0x27
db			'=[\]`'    					  , 0x00, 0x00, 0x00	; 0x2F
db			0x00, 0x00, 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x37
db			0x00, '.' , 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x3F
db			0x00, "abcdefghijklmnopqrstuvwxyz"					; 0x5A
db							  0x00  , 0x00, 0x00, 0x00, 0x00	; 0x5F
db			0x00, 0x00, 0x00, 0x00  , 0xA , 0x00				; 0x65
			


