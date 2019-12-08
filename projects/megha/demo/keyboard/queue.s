; DOS application to test circular queue

; The Queue structute
struc Q
	.length:	resb 2
	.width:		resb 2	; We only needed a byte, but a word is easier to work
						; with. Also some instructions like IMUL is more
						; flexible with word or double word.
	.head:		resb 2
	.tail:		resb 2
	.buffer:	resb 10
endstruc
			
;	org 0x100

;_start:

	; 1st item
;	mov bx, word_queue
;	mov ax, word1
;	call queue_put

	; 2nd item
;	lea ax, [word1 + 3]
;	call queue_put

	; 1st dequeue
;	mov ax, word2
;	call queue_get

	; 2nd dequeue
;	mov ax, word2
;	call queue_get		
;
	; Exit DOS
;	mov ah, 0x4c
;	int 0x21

;word1: db "abc","def"
;word2: resb 3

; Gets one element from the top of the queue
; Input:
;	DS:AX 	- Pointer to data. 
;			  WIDTH bytes will be copied to the queue buffer.
;	CS:BX	- Pointer to queue
; Output:
;	AX		- Number of bytes copied. 0 if queue empty.
queue_get:
; Algorithm:
; {
;	if (Q.head == Q.tail)
;		return EMPTY
;	Q.head = Q.head + 1 mod Q.length
;	return Q.buffer[Q.head]
; }

	push bx
	push di
	push dx
	push si
	push cx

		mov di, ax		; Move AX to SI, becuase AX cannot be used in effective
						; addressing.

		; Check if head == tail
		mov ax, [CS:bx + Q.head]
		cmp ax, [CS:bx + Q.tail]
		je .empty

		; head <> tail, we increment head and get the value.
		xor dx, dx
		inc ax
		div word [CS:bx + Q.length]	; The new index is in DX

		; Read Q.buffer[DX * WIDTH] 
		mov si, dx
		imul si, [CS:bx + Q.width]
		lea si, [CS:bx + Q.buffer + si] ; Address to location in buffer.
		; Copy WIDTH bytes from DS:SI to ES:DI
		push es
			push ds
			pop es

			mov cx, [CS:bx + Q.width]	
			rep movsb
		pop es

		mov [CS:bx + Q.head], dx		 ; Update head location

		; Success!! Read WIDTH into AX. 
		mov ax, [CS:bx + Q.width]		 
		jmp .end
.empty:
	xor ax, ax
.end:
	pop cx
	pop di
	pop dx
	pop di
	pop bx
	ret

; Put a value at the end of the queue
; Input:
;	DS:AX 	- Pointer to data. 
;			  WIDTH bytes will be copied to the queue buffer.
;	CS:BX 	- Pointer to queue
; Output:
;	AX		- Number of bytes copied. 0 if queue is full.
queue_put:
; Algorithm:
; {
;	if ((Q.tail + 1) mod Q.length) == Q.head
;		return FULL
;	Q.tail = (Q.tail + 1) mod Q.length
;	Q.buffer[Q.tail] = value
; }
	push dx
	push bx
	push di
	push si
	push cx

		mov si, ax		; AX cannot be used in effective affressing. SI will be
						; used as the pointer to source

		; Check if we can increment the TAIL.
		; That is if there is no room we will not add to the queue.
		xor dx, dx
		mov ax, [CS:bx + Q.tail]
		inc ax
		div word [CS:bx + Q.length]; The new index in the Queue buffer is in
								; DX (the remainder)

		cmp dx, [CS:bx + Q.head]
		je .full

		; There is room so we add to the queue.
		; Calculate the destination index in the buffer (new Tail value)

		mov di, dx				; DX cannot be used in effective addressing.

		imul di, [CS:bx + Q.width]	; Each if the item in buffer is WIDTH bytes
								; wide.
		lea di, [CS:bx + Q.buffer + di]

		; Copy WIDTH bytes from DS:SI to ES:DI
		push es
			push ds
			pop es

			mov cx, [CS:bx + Q.width]	
			rep movsb
		pop es

		mov [CS:bx + Q.tail], dx	; Update tail value

		; Success!! Read WIDTH into AX. WIDTH is 1 byte in size
		mov ax, [CS:bx + Q.width]	
		jmp .end
.full:
	xor ax, ax
.end:
	pop cx
	pop si
	pop di
	pop bx
	pop dx
	ret

; Queue instance
;word_queue:
;	.length:	dw 2
;	.width:		db 3	
;	.head:		dw 0
;	.tail:		dw 0
;	.buffer:	resb 20
