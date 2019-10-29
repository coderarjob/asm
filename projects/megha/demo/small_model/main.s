
; This is a demostration of the implementation of the DOS small program mode.
; Here all the pointers (within the program) is a near pointer, and this is
; ensured by the fact that DS = SS = CS


; Caller program

%macro call_small 3
	push ax
	push bx
	mov bx, sp
	mov cx, ss
	mov dx, ds

	mov ax, %1
	mov ds, ax
	cli
	mov ss, ax
	mov sp, %2
	sti

	push bx	;SP
	push cx ;SS
	push dx ;DS

	call %3

	pop ds  ;DS
	cli
	pop ax  ;SS
	pop bx  ;SP
	mov ss, ax
	mov sp, bx
	sti

	pop bx
	pop ax
%endm

; Setup the stack in the caller program
	cli
	mov ax, 0x6c0
	mov ss, ax
	mov sp, 0xfff
	sti

	push 0xfa18
	call_small 0x800, 0xfff, dummy
	pop ax

	mov ah, 0x4c
	int 0x21
	mov bx, sp
dummy:
	ret
