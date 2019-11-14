; Writes bytes to the console. It also interprets the CR, LF, H-TAB characters
; TODO: I need to implement a subset of the VT-100 escape sequence.
; Input:
;	DS:AX - Input buffer location
;	BX  - Length, Number of bytes to write
;	CX - Offset in the input buffer
write_term:
	pusha

	mov si, ax		
	add si, cx		; Add the offset to the Input buffer location

	mov cx, bx		; We loop as many times as the number of bytes in input.
	xor bx, bx		; From here on, BX will pointer to the current index in
					; .buffer array.
.again:
	lodsb

	cmp al, 0xA		; Check if current character is LF
	je .lf

	cmp al, 0xD		; Check if current character is CR
	je .cr

	cmp al, 0x9		; Check if current character is TAB
	je .tab

	cmp al, 0x8		; Check if current character is BACKSPACE
	je .backspace

	jmp .normal

.lf:
	; Character is LF
	inc byte [POSITION.row]
	jmp .update

.cr:
	; Character is CR
	mov [POSITION.column],byte 0
	jmp .update
.tab:
	; Character is Horizontal Tab
	add [POSITION.column], byte 4
	jmp .update
.backspace:
	; Character is backspace
	dec byte [POSITION.column]
	jz .dec_row
	jmp .update
.dec_row:
	mov [POSITION.column], byte COLUMNS -1
	dec byte [POSITION.row]

.update:		
	; Before we change the cursor position, we write the text
	; in the buffer at the current cursor position.
	mov ax, .buffer
	call write

	; Previously, the below routine was called in the .lf block. This produced
	; wrong result as we first scroll, then empty the buffer at the location as
	; it was before the scroll. In effect it resulted in the gaggered lines,
	; with the line previously written appearing above the line that is printed
	; in the .update block, even tough they must come once after another.
	call if_last_row_scroll_up_one_row	; row change is not applicable for CR
										; character. But called for now.

	mov al, [POSITION.column]
	mov bl, [POSITION.row]
	call set_cursor_location 

	; Rest internal buffer index
	xor bx, bx
	jmp .next
	
.normal:
	mov [.buffer + bx], al
	inc bx

	; 1. Check to see if position has reached the right most column
	inc byte [POSITION.column]
	cmp byte [POSITION.column], COLUMNS
	jne .buffer_full_check

	; We have reached the right most column, we go to the next line.
	; NEED TO SCROLL HERE IF CURRENT ROW IS => ROWS
	mov byte [POSITION.column], 0
	jmp .lf

	; 2. Check if internal buffer is full
.buffer_full_check:
	cmp bx, .length
	jne .next

	; Internal buffer is full. We send the complete buffer to the console
	mov ax, .buffer
	mov bx, .length
	call write

	; Reset the internal buffer value. Should start from the top.
	xor bx, bx
.next:
	loop .again

	; We write what ever is in the buffer.
	mov ax, .buffer
	call write
.end:
	popa
	ret	

.buffer: resb 20
.length: equ $ - .buffer

if_last_row_scroll_up_one_row:
	push ax
		; Check if we have reached the end of the PAGE
		mov al, [POSITION.last_row]
		cmp [POSITION.row],al
		jbe .end

		; We are scrolling up because we have reached the end of the screen.
		inc byte [POSITION.start_row]
		inc byte [POSITION.last_row]
		
		mov ax, [POSITION.start_row]
		call scroll_up

		; Check if we have gone to the last page.
		; If we have then start_row must be the first line of the last page.
		cmp [POSITION.start_row], byte FIRST_ROW_LAST_PAGE
		jb .end

		; start_row has gone past the first line of the last page.
		mov [POSITION.start_row], byte FIRST_ROW_LAST_PAGE

		; last_row has gone past the last line of the last page
		mov [POSITION.last_row], byte LAST_ROW_LAST_PAGE

		; current row has gone past the last line
		mov [POSITION.row], byte LAST_ROW_LAST_PAGE
.end:
	pop ax
	ret

POSITION:						; -- INVARIANTS --
	.row: db 0					; 0 <= row <= ROWS -1
	.column: db 0				; 0 <= column <= COLUMNS -1
	.start_row: db 0			; 0 <= start_row <= FIRST_ROW_LAST_PAGE
	.last_row: db ROWS -1		; ROWS -1 <= last_row <= LAST_ROW_LAST_PAGE

;COLUMNS: 80
PAGES: EQU 1
ROWS: EQU 25
%if PAGES = 1
	LAST_ROW_LAST_PAGE: EQU (PAGES * ROWS) -1
%else
	LAST_ROW_LAST_PAGE: EQU (PAGES * ROWS) -2
%endif

FIRST_ROW_LAST_PAGE: EQU (PAGES -1) * ROWS
