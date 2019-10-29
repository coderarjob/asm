
	org 0x100

	les ax, [far_pointer]

	mov ax, filepath_with_name
	mov cx, ':'
	mov dx, 0
	call str_indexof

	mov [filepath_with_name + bx + 1], byte 0

	mov ah, 0x4c
	int 0x21

far_pointer: dw 0xFFFF, 0x0001
; Find index of a character in the asciiz string
; Input:
;		DS:AX = location of string
;		CX = Character to find
;		DX = Start index
; Output:
;		BX = index of the character. First character is at location 0
str_indexof:		
	push si
	push ax

		mov si, ax
		mov bx, dx
		add ax, dx
.again:
		lodsb
		cmp al, 0
		je .not_found

		cmp al, cl
		je .end

		inc bx
		jmp .again
.not_found:
		mov bx, 0xFFFF
.end:
	pop ax
	pop si
	ret

filepath_with_name: db 'c:\windows\explorer.exe',0
