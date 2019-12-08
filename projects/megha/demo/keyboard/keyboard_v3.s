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

	mov ax, 0x3
	call set_attribute
.check:	

	mov dh, [keyboard_queue + Q.head]
	mov dl, [keyboard_queue + Q.tail]
	call printhex

	mov cx, 0x2
	mov dx, 0xA0
	mov ah, 0x86
	int 0x15

	; Ask the keyboard to return from the queue.
	; If there are no items, it returns 0
	mov ax, keyboard_queue_item			; Store here
	mov bx, 4							; Read 4 bytes from the buffer
	mov cx, 0							; Store at offset 0 bytes
	call keyboard_read_queue

	cmp ax, 0		; No items in the queue
	je .check
	
	; -------------------------
	; Read ASCII code
	; -------------------------
	mov al, [keyboard_queue_item + kQi.keycode]
	mov bl, [keyboard_queue_item + kQi.flags]
	mov cl, [keyboard_queue_item + kQi.ascii]
	
	;mov dl, cl
	;call printchar
	;mov dx, [keyboard_queue_item + kQi.keycode]
	;call printhex

	cmp al, 1
	je .end

	test bl, byte PRESSED
	jz .check

	cmp cl, 0
	je .check

	mov [string], cl
	mov bx, 1

	cmp cl, 0xA
	jne .anykey
	
	; LF is received, we need to put CR as well.
	mov [string + 1], byte 0xD
	mov bx, 2

.anykey:
	mov ax, string
	mov cx, 0
	call write_vga

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

keyboard_queue_item: resb 4
string: dw 0

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
		jmp .extended_get_next_key 		; We do not add 0xE0 to the output and
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
		cmp ah, key_codes.LSHIFT
		je .n2a					; It is Left Shift Key

		; --- Check for Right Shift key
		cmp ah, key_codes.RSHIFT
		jne .n3					; Neither of the SHIFT keys
.n2a:
		; --- Check if pressed or released
		test [key.flags], byte PRESSED	
		jz .n2_rel			; SHIFT key is being released not pressed.

		; SHIFT key is being PRESSED.
		or [key.flags], byte SHIFT		; SET SHIFT Flag
		jmp .end
.n2_rel:
		and [key.flags], byte ~SHIFT	; CLEAR SHIFT Flag
		jmp .end
.n3:
		; ----------------------------------------
		; Check for CONTROL key press
		; ----------------------------------------
		
		cmp ah, key_codes.LCTRL
		je .n3_ctrl			; It is the Left CONTROL key

		cmp ah, key_codes.RCTRL
		jne .n4				; Not any of the CONTROL Keys.

.n3_ctrl:
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
		
		cmp ah, key_codes.LALT
		je .n4_alt			; It is the Left ALT key

		cmp ah, key_codes.RALT
		jne .n5				; Not any of the ALT Keys, Continue

.n4_alt:
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

		cmp ah, key_codes.CAPS
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

		cmp ah, key_codes.NUM
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

		cmp ah, key_codes.SCROLL_LOCK
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

.cont:
		; We add to the queue here
		mov ax, key
		mov bx, keyboard_queue
		call queue_put


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

; Reads from the keyboard queue
; Input
; 	DS:AX	- Location to copy items from the buffer
; 	BX		- Number of bytes to be read from the queue. 
;			  If not a multiple of 4, BX is floor(BX / 4). 4 is the WIDTH of
;			  the keybaord queue.
;	CX		- Bytes offset in the output buffer.
;			  First byte copied will be at DS:AX + CX
; Output:
;	AX		- Number of bytes returned.
keyboard_read_queue:
	push cx
	push bx
	push di
	push dx

	; AX cannot be part of effective addressing, we copy it to DI
	mov di, ax
	add di, cx		; Add the offset (CX is the number of bytes)

	; Copy the count to CX for easier manupulation
	; Note: if BX = 3, then after the below DIV, BX = 0 (Nothing is read)
	push ax
		xor dx, dx
		mov ax, bx
		div word [CS:keyboard_queue + Q.width]
		mov bx, ax
	pop ax

	mov cx, bx

	; DX holds the number of bytes copied from queue
	xor dx, dx		; Clear DX register.

	; If CX is 0, we go to the end.
	jcxz .end	

.again:
	mov ax, di
	mov bx, keyboard_queue
	call queue_get		; AX - Pointer to destination, BX - Pointer to queue.
	
	cmp ax, 0
	je .end

	add di, ax		; AX = number of bytes in quue item. Increment destination
					; address to get the next write location.
	add dx, ax		; Increment byte count
	loop .again

.end:
	mov ax, dx		; AX returns the number of bytes copied

	pop dx
	pop di
	pop bx
	pop cx
	ret

; Prints 16 bit hex number
; Input: DX
printhex:
	push gs
	pusha	; push all general purpose registers

		; setup the segment registers
		mov bx, 0xb800
		mov gs,bx
		;mov bx, [cpos]	; load the current memory offset to write to.
		mov bx, 0x780	; 24th Line, 1st column

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

; -----------------------------------------------------------------
; Key code to ASCII Mapping
;
; Key codes with combinations of SHIFT key and CAPS lock key and NUM lock key
; are mapped to get corresponding ASCII codes.
;
; -----------------------------------------------------------------


; Sets the ASCII Code for the key code.
; Input: 
;	Reads from Key.keycode, and Key.Flags
; Output: 
;	Modifies key.ASCII

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
		jz .normal 							; CAPS is not PRESSED.

		xor ax, ax							; CAPS is PRESSED.
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

modifiers_routines: 
dw					get_ascii.no_modifier_keys
dw					get_ascii.shift_modified_keys
dw					get_ascii.shift_caps_modified_keys
dw					get_ascii.caps_modified_keys
dw					get_ascii.num_modified_keys

old_kb_int_offset: dw 1
old_kb_int_seg: dw 1

; Keyboard Queue Item structure (4 bytes)
struc kQi		
	.flags:		resb 1
	.scancode:	resb 1
	.keycode:	resb 1
	.ascii:		resb 1
endstruc

key:
	
; ==========================================================
; Keyboard queue item consists of 4 bytes:
; |   3   |   2      |   1     |   0   |
; |-------|----------|---------|-------|
; | Flags | scancode | keycode | ascii |
; |-------|----------|---------|-------|
;
; These 4 bytes will be added to the queue everytime a key is 
; pressed or released. If the keyboard buffer is full, then 
; no new key gets added to the queue. Repeating keys also add 
; the same 4 bytes.
; ==========================================================

; |---------------- Flags Bit Map --------------------|
; |    7  |    6   |    5     | 4 | 3  |  2  | 1  | 0 |
; |-------|--------|----------|---|----|-----|----|---|
; |Pressed|Extended|ScrollLock|ALT|CTRL|SHIFT|CAPS|NUM|
; |-------|--------|----------|---|----|-----|----|---|
	.flags db 0			
		NUM: EQU 0x1
		CAPS: EQU 0x2
		SHIFT: EQU 0x4
		CTRL: EQU 0x8
		ALT: EQU 0x10
		SCROLL_LOCK: EQU 0x20
		EXTENDED: EQU 0x40
		PRESSED: EQU 0x80
	.scancode db 0
	.keycode db 0
	.ascii db 0
; ==========================================================
; For use only by driver
; ==========================================================
	.leds db 0
		SCROLL_LED: EQU 0x1
		NUM_LED: EQU 0x2
		CAPS_LED: EQU 0x4
	.caps_state db 0
	.nums_state db 0
	.scroll_state db 0
	; -----------------------------------


keyboard_queue:
	.length:	dw 40
	.width:		dw 4
	.head:		dw 0
	.tail:		dw 0
	.buffer:	resb 160

; -----------------------------------------------------------------
; Scan code to Key code map
; Legend: 
;		  Numbers      : 0		   --> 0xB
;						 1 - 9     --> 0x2 0xA
;		  Num KeyPad   : 0 - 9     --> 0xE to 0x17
;         Space        :           --> 0x1A
;		  Function keys: F1 to F12 --> 0x2D to 0x38
;         Characters   : A - Z     --> 0x41 to 0x5A
;		  Arrow Keys   : Down      --> 0x5F
;					   : Left      --> 0x5C
;					   : Right     --> 0x5D
;					   : Up        --> 0x40
;		  Delete Key   :           --> 0x62
;         Win          :           --> 0x63
;         Menu         :           --> 0x65
;         Enter        : Normal    --> 0x18
;                      : NumPad    --> 0x64
; Extended Keys:
;		  Because Extended Keys can have same Scan Codes as 
;		  another key in the keyboard (but some are unique)
;			|===========|==========|
;		  	| Scan code |   Key    |
;			|===========|==========|
;			|   0x5B    |  Windows |
;			|-----------|----------|
;			|   0x5D    |  Menu    |
;			|-----------|----------|
;			|   0x1D	| L Control|
;			|-----------|----------|
;			|   0x1D    | R Control|
;			|===========|==========|
;
; 		  In order to use the existing mapping table (below), We Shift the 
;		  scan codes of Extended keys so that the modified scan codes, all 
;		  start at location 0x64 (the last scan code ended at 0x58 (F12)).
;
;		  0x64 was chosen as it is larger than than the largest scan code, 
;		  there is no other reason. 
;
;		  This means that the Extended Key with the lowest Scan code starts at
;		  location 0x64. (0x1C is the lowest)
;
;		  Modified Scan code: [Scan Code (byte 2)] + 100 - 0x1C
;		  ------------------
;
;		  Drawbacks:
;		  ----------
;		  This method however does nothing to make the extended keys closer, so
;		  that less space is wasted.
;		 
; -----------------------------------------------------------------
key_codes:
; The below contants are used to identify if LEFT SHIFT, CAPS, ALT keys are
; pressed. Previously we used to perform this identification using Scan codes,
; but that will make them hardwired to the keyboard hardware. 
; To make the below contants independent of the keyboard hardware, 
; we assign *Key Codes* to them.

	;-------------|-----------|
	; Constant    | Key Codes |
	;-------------|-----------|
	.LSHIFT: 		EQU 0x1C 
	.RSHIFT: 		EQU 0x23
	.CAPS: 	 		EQU 0x26	
	.LALT: 	 		EQU 0x25	
	.RALT: 	 		EQU 0x3E
	.LCTRL:			EQU 0x19	
	.RCTRL: 	 	EQU 0x3C	
	.NUM:			EQU 0x3A	
	.SCROLL_LOCK: 	EQU 0x3B	
	;-------------|----------|

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
	;   -----------------------------------------------
	; [ Extended keys: Modified Scan codes to Key Codes ]
	;   -----------------------------------------------
	db 0x64, 0x3C,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ; 0x78
	db 0,0,0,0,0,0,0x3D, 0x3E, 0,0,0,0,0,0,0,0,0,0		; 0x8A
	db 0,0,0,0,0x3F,0x40,0x5B, 0,0x5C,0,0x5D,0,0x5E		; 0x97
	db 0x5F, 0x60, 0x61, 0x62, 0,0,0,0,0,0,0,0x63,0		; 0xA4
	db 0x65												; 0xA5

modifier_maps:

	NONE:	 	EQU 0	; Keys that never change its meaning or function.
	M_SHIFT:	EQU 1	; Keys that change behaviour when SHIFT is pressed.
	M_SCAPS:	EQU 2	; Keys that change behaviour depending on both SHIFT and CAPS LOCK.
	M_CAPS:		EQU 3	; Keys that change behaviour depending on CAPS LOCK.
	M_NUM:		EQU 4	; Keys that change behaviour depending on NUMS LOCK.

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
db			'7890'                  , 0x08, 0x09, 0x00, 0x00	; 0xF
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
db			'&*()'                  , 0x08, 0x09, 0x00, 0x00	; 0xF
db			0x00, 0x00, 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x17
db			0xA , 0x00, ' ' , '"' 	, 0x00, '_' ,  '+',  '-'	; 0x1F 
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
db			'7890'                  , 0x08, 0x09, 0x00, 0x00	; 0xF
db			0x00, 0x00, 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x17
db			0xA , 0x00, ' ' , "'" 	, 0x00, '-' ,  '+',  '-'	; 0x1F 
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
db			'&*()'                  , 0x08, 0x09, 0x00, 0x00	; 0xF
db			0x00, 0x00, 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x17
db			0xA , 0x00, ' ' , '"' 	, 0x00, '_' ,  '+',  '-'	; 0x1F 
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
db			'7890'                  , 0x08, 0x09, '0123456789'	; 0x17
db			0xA , 0x00, ' ' , "'" 	, 0x00, '-' ,  '+',  '-'	; 0x1F 
db			',' , '.' , '/' , 0x00  , '*' , 0x00, 0x00, ';'		; 0x27
db			'=[\]`'    					  , 0x00, 0x00, 0x00	; 0x2F
db			0x00, 0x00, 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x37
db			0x00, '.' , 0x00, 0x00  , 0x00, 0x00, 0x00, 0x00	; 0x3F
db			0x00, "abcdefghijklmnopqrstuvwxyz"					; 0x5A
db							  0x00  , 0x00, 0x00, 0x00, 0x00	; 0x5F
db			0x00, 0x00, 0x00, 0x00  , 0xA , 0x00				; 0x65
			

%include "queue.s"
%include "terminal.s"
