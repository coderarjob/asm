
; This program will print hex hump of a protion of memory

	ORG 0x100

	mov si, 0xb800		; Memory segment
	mov es, si		
	mov si, 0		; Memory offset to start from
	mov cx, 0x80		; Number of bytes to show
	mov ax, 0	
	jmp .headers
.again:
	cmp ax, 16
	jne .body

	; Dump out the previous tempate
	pusha
	    mov si, dump_body
	    mov cx, master_len
	    call copy_to_screen
	popa

.headers:
	; Copy the master to dump_body
	pusha
	push es
		mov bx, ds
		mov es, bx
		mov si, master
		mov di, dump_body
		mov cx, master_len
		rep movsb
	pop es
	popa

	; print the address to the left
	pusha
	    ; Print segment
	    mov bx, es
	    mov al, 16
	    lea di, [dump_body + 1]
	    call printhex
		
            ; Print offset
	    mov bx, si
	    mov al, 16
	    lea di, [dump_body+6]
	    call printhex

	popa

	; Body starts from template + 13
	lea di, [dump_body+13]

	; number of bytes out of 16 completed in body.
	; It is zero, as no bytes are written to body after headers.
	mov ax, 0
.body:
	push bx
	    ; print in hex
	    push ax
		xor bx, bx
		mov bl, [es:si]
		mov al, 8
		call printhex
	    pop ax

	    ; print ascii chars
	    push di
		lea di, [dump_body+master_len-18]
		add di, ax
		mov [ds:di],bl
	    pop di
	pop bx

	inc si
	add di, 3
	inc ax

	loop .again

	; Dump out the last tempate
	mov si, dump_body
	mov cx, master_len
	call copy_to_screen

	; exit dos
	mov ah, 0x4c
	int 0x21


; Copies bytes from local to vga
; Input: DS:SI - location of local string
;        CX    - number of bytes
; Output: none
copy_to_screen:
	pusha
	push es
		mov bx, 0xb800
		mov es, bx
		mov di, [location]
.rep:
		lodsb
		cmp al, 13
		je .cr
		
		cmp al, 10
		je .lf

		mov [es:di], al
		mov [es:di+1], byte 0xF
		add di, 2
		jmp .loop
.lf:
		call LF
		jmp .loop
.cr:
		call CR
.loop:
		loop .rep
		
		mov [location], di
	pop es
	popa
	ret

; Prints hex representation of a number. The number of least significant bits
; to print also needs to be specified.
; Input:
;      BX - Number
;      DS:DI - Address to write to
;      AL - Number of LSbits to print. Valid values are 16,12,8 and 4
; Output: none
printhex:
	pusha
	push es
		xor ah, ah

		; adjust the number of bits to print based of AL
		; BX = BX << (16 - AL)
		mov cx, 16
		sub cx, ax ; Cannot be SUB CX, AL

		shl bx, cl

		; set the number of itterations needed to show AL LSbits
		; CX = AL/4
		shr ax, 2
		mov cx, ax

		; Save the number in DX
		mov dx, bx

		; restore the number
.again:
		mov bx, dx
		shr bx, 12
		mov bl, [hexchars + bx]

		mov [ds:di],bl
		inc di
		
		shl dx, 4
		loop .again
	pop es
	popa
	ret

; Changes the print address, so that the next character prints at the beginning
; of the current line
; Input: DI
; Output: DI
CR:
	; Operation: Current line start address = loc - (loc % 160)
	push ax
	push bx
		mov ax, di
		mov bl, 160
		div bl

		xor bx, bx
		mov bl, ah		; Remainder is in AH
		sub di,bx		; SUB works only with register of
					; matching length.
	pop bx
	pop ax
	ret

; Changes the print address, so that the next character exactly below
; of the current position.
; Input: DI
; Output: DI
LF:
	add di, word 160
	ret

section .data
hexchars: db "0123456789ABCDEF"
location: dw 0
master: db " ----:----                                                  "
        db "                  ",13,10
master_len: equ $-master

section .bss
dump_body: resb master_len
