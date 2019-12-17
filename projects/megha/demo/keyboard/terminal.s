; A DOS program that demostrates and prototypes all the operations that need to
; be implemented into the Console.mod module of Megha Operating System.

; Features:
; * Cursor operations
; * Scroll operations
; * Curosor and Font attributes

	%include "vga.s"

; Writes to the terminal OUT Queue or directly to VGA if buffering is disabled.
; Input:
;	DS:AX	- Input data location
;	BX		- Number of bytes to write
;	CX		- Offset in bytes in the input buffer
sys_term_term:
	
	ret

; Reads from the keyboard queue. It reads multiple of 
; Input Queue Width (4 bytes). We are going to read AT-MOST BX bytes.
;
; Input:
;	DS:AX	- Output data location
;	BX		- Number of bytes to read.
;			  If this is not a multiple of 4, BX is floor(BX / 4).
;	CX		- Offset in bytes in the output buffer
;			  First byte copied will be at DS:AX + CX
; Output:
;	AX		- Number of bytes returned
sys_term_read:
	push di
	push cx
	push bx
	push dx

	mov dh, [CS:IN_QUEUE + Q.head]
	mov dl, [CS:IN_QUEUE + Q.tail]
	call printhex

	mov di, ax		; AX cannot be used for Effective address calculations
	add ax, cx		; Add offset to the output location.

	; We will use CX for keeping track of the number of bytes read.
	; Note: If BX = 3, then after the below DIV, BX = 0 (Nothing will be read)
	push dx
		xor dx, dx
		mov ax, bx
		div word [CS:IN_QUEUE + Q.width]
		mov bx, ax
	pop dx
	mov cx, bx		; CX will be used to keep track of the number of bytes

	xor dx, dx		; We are counting the number of bytes read in DX
	
	jcxz .end		; CX = 0; we end
.again:
	mov ax, di
	mov bx, IN_QUEUE
	call queue_get	; DS:AX - Pointer to destination, CS:BX - Pointer to queue.

	cmp ax, 0
	je .end

	add di, ax		; AX = number of bytes in the queue item. Increment
					; destination address to get the next write locaiton.
	add dx, ax		; Increment the bytes count
	loop .again
.end:
	mov ax, dx		; Return the number of bytes copied

	pop dx
	pop bx
	pop cx
	pop di
	ret

; Adds a key (4 bytes) to the IN queue.
; It also processes CTRL + C and can use used to terminate the current process.
; Input:
;	DS:AX	- Pointer to the key bytes
; Ouput:
;	None
sys_term_keyboard_hook:
	push bx
		mov bx, IN_QUEUE
		call queue_put
	pop bx
	ret

; Writes bytes to the console. It also interprets the CR, LF, H-TAB characters
; TODO: I need to implement a subset of the VT-100 escape sequence.
; Input:
;	DS:AX 	- Input buffer location
;	BX  	- Length, Number of bytes to write
;	CX 		- Offset in the input buffer
write_vga:
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
	call sys_vga_write

	; Reset the internal buffer value. Should start from the top.
	xor bx, bx
.next:
	loop .again

	; We write what ever is in the buffer.
	mov ax, .buffer
	call sys_vga_write
.end:
	popa
	ret	
; ----------------------------------------------------
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
	cmp [POSITION.column], byte COLUMNS		; Check if last COLUMN is reached.	
	jb .update
	
	; Reached the last column, increment row. 
	; Will scroll if it is the last row.
	sub [POSITION.column], byte COLUMNS		; Tab should continue to the next
											; line. If we pressed tab on column
											; 78, then 78 + 4 = 82. So next 
											; letter should be at column 
											; index 80 - 82 = 2, in the next
											; line. Thus columns 78,79,0,1
											; should be convered by the tab 
											; key.
	inc byte [POSITION.row]
	jmp .update
.backspace:
	; Character is backspace
	dec byte [POSITION.row]
	jmp .update 

	dec byte [POSITION.column]
	cmp [POSITION.column],byte 0	; We do not decrement row at column 0, 
	jge .update						; We do a signed comparison. If column < 0
									; then we decrement row.

	; Column < 0
	mov [POSITION.column], byte COLUMNS -1
	dec byte [POSITION.row]

	cmp [POSITION.row], byte 0
	jge .update

	; Row < 0
	; Cannot Backspace as we are already on the last row.
	mov byte [POSITION.row], 0
	mov byte [POSITION.column], 0
	jmp .next						; No change was made, so no need to update.

.update:		

; Before we change the cursor position, we write the text
; in the buffer at the current cursor position.
	mov ax, .buffer
	call sys_vga_write

	; SCROLL UP NEEDED??

	; Previously, the below routine was called in the .lf block. This produced
	; wrong result as we first scroll, then empty the buffer at the location as
	; it was before the scroll. In effect it resulted in the gaggered lines,
	; with the line previously written appearing above the line that is printed
	; in the .update block, even tough they must come once after another.
	mov al, [POSITION.last_row]
	cmp [POSITION.row],al
	jle .scroll_down_check			; row =< last_row (signed), 
									; so we do not scroll up

	call scroll_up_one_row			; row change is not applicable for CR
									; character. But called for now.

	; SCROLL DOWN NEEDED??
.scroll_down_check:
	mov al, [POSITION.start_row]
	cmp [POSITION.row], al			; Check is row < first_row (signed)
	jge .set_cursor_location		; row >= first_row, so we dont scroll down.
	
	call scroll_down_one_row

.set_cursor_location:
	mov al, [POSITION.column]
	mov bl, [POSITION.row]
	call sys_vga_set_cursor_location 

	; We just flushed out the entire buffer.
	; Rest internal buffer index.
	xor bx, bx
	jmp .next
; ----------------------------------------------------

.buffer: resb 20
.length: equ $ - .buffer

scroll_up_one_row:
	push ax
		; We are scrolling up because we have reached the end of the screen.
		inc byte [POSITION.start_row]
		inc byte [POSITION.last_row]

		; The below instruction is just to keep ensure invariables are
		; preserved. 
		; The scroll_up_one_row() routine is called in the .update block only
		; when row > last_row (more specifically row = last_row + 1).
		; So when we come at this point in the instruction row = last_row (we
		; have incremented last_row above). 
		; But in the odd chance, that one calls this routine without the check 
		; in .update (mentioned above), we will have a broken our invariables. 
		; The below instruction ensures invariables are preserved.
		mov al, [POSITION.last_row]
		mov [POSITION.row], al
	
		; Scroll up
		mov ax, [POSITION.start_row]
		call sys_vga_scroll_up

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

scroll_down_one_row:
	push ax

		dec byte [POSITION.start_row]
		dec byte [POSITION.last_row]

		; The below instruction is just to keep ensure invariables are
		; preserved. 
		; Line in the case of scroll_up, the .update block checks if 
		; row < start_row (more specifically, row = start_row -1), before 
		; calling scroll_down_one_row() routine. So at this point in the
		; routine, row = start_row anyways. But without the above mentioned
		; check, we have a broken invariable.
		mov al, [POSITION.start_row]
		mov [POSITION.row], al

		cmp byte [POSITION.start_row],0		; Check if start row < 0
		jl .reset							; start_row < 0, we reset
		
		mov al, [POSITION.start_row]
		call sys_vga_scroll_down
		jmp .end

.reset:
		mov [POSITION.start_row], byte 0
		mov [POSITION.last_row], byte ROWS -1
		mov [POSITION.row],byte 0
.end:
	pop ax
	ret

POSITION:						; -- INVARIANTS --
	.row: 		db 0			; 0 <= row <= ROWS -1
	.column: 	db 0			; 0 <= column <= COLUMNS -1
	.start_row: db 0			; 0 <= start_row <= FIRST_ROW_LAST_PAGE
	.last_row: 	db ROWS -1		; ROWS -1 <= last_row <= LAST_ROW_LAST_PAGE

IN_CONFIG: 	db 1
OUT_CONFIG: db 1

IN_QUEUE:
	.length:	dw 60
	.width:		dw 4
	.head:		dw 0
	.tail:		dw 0
	.buffer:	resb 240

OUT_QUEUE:
	.length:	dw 40
	.width:		dw 1
	.head:		dw 0
	.tail:		dw 0
	.buffer:	resb 40

%include "queue.s"
