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

	mov cx, bx
	xor bx, bx
.again:
	lodsb

	cmp al, 0xA		; Check if current character is LF
	je .lf

	cmp al, 0xD		; Check if current character is CR
	je .cr

	jmp .normal

.lf:
	; Character is LF
	inc byte [POSITION.row]
	call if_last_row_scroll_up
	jmp .update

.cr:
	; Character is CR
	mov [POSITION.column],byte 0

.update:		
	; Before we change the cursor position, we write the text
	; in the buffer at the current cursor position.
	mov ax, .buffer
	call write

	mov al, [POSITION.column]
	mov bl, [POSITION.row]
	call set_cursor_location 

	;mov dx, [POSITION.row]
	;call printhex

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
	inc byte [POSITION.row]
	call if_last_row_scroll_up

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

if_last_row_scroll_up:
	; Check if we have reached the end of the screen.
	cmp [POSITION.row],byte ROWS
	jb .end

	; We are scrolling up because we have reached the end of the screen.
	inc byte [POSITION.start_row]
	inc byte [POSITION.end_row]
	
	mov ax, [POSITION.start_row]
	call scroll_up

	; Check if we have gone to the last page.
	; If we have then start_row must be the first line of the last page.
	cmp [POSITION.start_row], byte (PAGES - 1) * ROWS
	jb .end

	; start_row has gone past the first line of the last page.
	mov [POSITION.start_row], byte (PAGES -1) * ROWS
	mov [POSITION.end_row], byte (PAGES * ROWS) -1
.end:
	ret

POSITION:
	.row: db 0
	.column: db 0
	.start_row: db 0
	.end_row: db 24

;COLUMNS: 80
PAGES: EQU 8
ROWS: EQU 25
