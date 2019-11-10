; A DOS program that demostrates and prototypes all the operations that need to
; be implemented into the Console.mod module of Megha Operating System.

; Features:
; * Cursor operations
; * Scroll operations
; * Parsing of \n\r\t values
; * Operations to implement CR, LF and HTAB

	%macro _out 2
		push ax
		push dx
			mov dx, %1
			mov al, %2
			out dx, al
		pop dx
		pop ax
	%endmacro

; Writes to the VGA memory. It also advances the cursor when needed.
; This routine, may also interpret Carriage return, Line Feed, and Tab
; characters as well. I am not really sure where to do the CR, LF, and HTAB
; character processing. Shoud I do it in the Terminal driver?? 
; Input:
; 	DS:AX - Buffer location.
;	BX - Buffer length
write:
	push cx
		mov cx, bx			; We need to copy these many bytes
		jcxz .empty			; We end, if length provided is zero

	push es
	push si
	push di
	push ax
	push bx

		mov bx, MEM.seg		; We load the destination segment register
		mov es, bx

		mov si, ax
		mov di, [MEM.now]
		mov ax, [ATTRIBUTE.value]
.again:	
		movsb
		mov [es:di],al
		inc di
		loop .again

	pop bx
		; For each character, we have to advance memory location by 2 bytes. 
		; So we add BX twice. We could have used SHL BX, 1 instruction, 
		; but then we had to put extra instructions to preserve and restore BX.
		add [MEM.now], bx	; Update the current memory location once
		add [MEM.now], bx	; Update the current memory location twice.

		;We need to update Cursor location here
		add [CURSOR.location], bx		; We add the number of bytes written to
										; the current cursor position
		mov bx, [CURSOR.location]		; Save the Updated location
		call __set_cursor_location		; Change the VGA Cursor location
										; registers. Input is BX.
	pop ax
	pop di
	pop si
	pop es
.empty:
	pop cx
	ret

; Scrolls down the screen.
; Input:
; 	AL - First row to display
scroll_up:
	pusha

	xor ah, ah
	; Check if we have reached the last page.
	; If the first row + ROWS >= the last page row then we are working with the
	; last page. The last page needs to be treated sepatately.
	;mov dx, 0xbabe
	;call printhex

	push ax
		add ax, ROWS
		cmp ax, (PAGES * ROWS)
	pop ax
	jae .last_page

	; We are not dealing with the last page. So scroll down is as simple as
	; calling the set_origin method
	imul ax, COLUMNS;

	call set_origin
	jmp .end

.last_page:
	
	; There is no room for any more line. So drastic measureus need to be
	; taken. We destroy the very first line and copy the 2nd line in its place.
	; Then we copy the 3rd line to 2nd line, and so on untill we have copied 
	; the very last to the 2nd last line.

	; From the start to the end, there are 25 * 8 = 200 lines. We will do till
	; the 2nd last line, so 199th line.
	
	mov cx, (PAGES * ROWS) -1;
	mov si, COLUMNS * 2			; This is the start of the very 2nd line.
	mov di, 0					; This is the start of the very first line.
	rep movsb					; We will keep coping till the start of the
								; very last line of the last page.
	
	; Now we make the last line blank.
	mov cx, COLUMNS * 2
	mov al, 0
	rep stosb
.end:
	popa
	ret
; Sets the cursor location on the screen.
; This also updates the current location (MEM.now) as well to the proper value.
; Input:
; 	Al - Column number (starts from 0)
;	Bl - Row number (starts from 0)
set_cursor_location:
	push ax
	push bx
		
		xor ah, ah
		xor bh, bh

		; Need to convert the rows and columns to linear address.
		; offset = row * COLUMNS + column
		imul bx, COLUMNS
		add bx, ax

		; Update VGA cursor location registers.
		; Input is the Text Cell index (Staring with 0), in BX register
		call __set_cursor_location

		; Save the current location
		mov [CURSOR.location], bx

		; Update the screen memory location
		; Every text cell on screen takes two bytes. So
		; mem location = offset * 2
		shl bx, 1
		mov [MEM.now], bx
	pop bx
	pop ax
	ret

; Similar to the method above, but takes in the location as text cell index
; rather than columns and rows.
; Note: This is a routine used locally by the driver.
; Input:
;	BX - Text cell index. (Top left cell is 0)
__set_cursor_location:
	; Set the Cursor Location Low Register	
	_out 0x3d4, 0xF
	_out 0x3d5, bl

	; Set the Cursor Location High Register
	_out 0x3d4, 0xE
	_out 0x3d5, bh 
	ret
	
; Sets the offset text cell number, from which the to display starts.
; Setting this to 80 (on a 80 column monitor), will start display from the 
; 2nd line. This routine will be used to reset the start memory at the 
; beginning and also can be used for vertical scrolling.
; Input:
;	AX - Offset value
set_origin:
	; 1. Set the low byte into the VGA Start Memory Register
	_out 0x3d4, 0xD
	_out 0x3d5, al

	; 2. Set the High byte into the VGA Start Memory Register
	_out 0x3d4, 0xC
	_out 0x3d5, ah
	ret

; Sets the attribute (Fore Color, Background Color and Blink)
; Input:
;	AL - Attributes. 
;   |---|-----------|---------------|
;   | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;   |---|-----------|---------------|
;   | B | FG Color  | BG Color      |
;   |---|-----------|---------------|
;set_attribute:
	;mov [ATTRIBUTE.value], al
	;ret

; Sets the attribute (Fore Color, Background Color and Blink)
; Input:
;	AH - Attribute selection ( 0 - FG color, 1 - BG Color, 2 - Blink)
;	AL - Attribute value
set_attribute:
	cmp ah, 0
	je .fg_color

	cmp ah, 1
	je .bg_color
	
	cmp ah, 2
	je .blink

	jmp .invalid

.fg_color:
	and [ATTRIBUTE.value],byte 0b11110000
	or [ATTRIBUTE.value], al
	jmp .end
.bg_color:
	and [ATTRIBUTE.value],byte 0b10001111
	shl al, 4
	or [ATTRIBUTE.value], al
	jmp .end
.blink:
	and [ATTRIBUTE.value],byte 0b01111111
	shl al, 7
	or [ATTRIBUTE.value], al
.invalid:
.end:
	ret

; Sets the cursor shape
; Input:
;	AL - Cursor start scan line
;	AH - Cursor end scan line
set_cursor_attribute:
	push ax
	; Set the Cursor Start Register
	; We will set the CD (Cursor Display) bit to 1
	or al, CURSOR.CD_ON
	and al, 0xF			; Only the right most 4 bits are importaint

	_out 0x3d4, 0xA
	_out 0x3d5, al

	; Set the Cursor End Register
	; We will set the CSK (Cursor Skew) bits to 0
	and ah, 0xF			; We keep only the right most 4 bits.

	_out 0x3d4, 0xB
	_out 0x3d5, ah
	
	pop ax
	ret

MEM: 
	.seg equ 0xB800
	.now dw 0

COLUMNS: equ 80

ATTRIBUTE:
	.value: db 0xF

CURSOR:
	.location: dw 0
	.CD_ON: EQU 0b_0010_0000

%include "terminal.s"
