; Bootloader program that shows the value of different registers.

%define DOS

%ifdef	DOS
	; DOS program
	org 0x100
%else
	; Bootloader program
	org 0x7C00
	%include "../bpb.s"
%endif

boot_main:
	mov si,regs

	; print DX
	call print_from_dest
	call printhex

	; print SP
	call print_from_dest
	mov dx, sp
	call printhex

	; print DS
	call print_from_dest
	mov dx, ds
	call printhex
	
	; print CS
	call print_from_dest
	mov dx, cs
	call printhex
	
	; print SS
	call print_from_dest
	mov dx, ss
	call printhex
	
	; print ES
	call print_from_dest
	mov dx, es
	call printhex
	
	; print GS
	call print_from_dest
	mov dx, gs
	call printhex

	; print FS
	call print_from_dest
	mov dx, fs
	call printhex


	; complete
%ifdef DOS
	; DOS program exit
	mov ah, 0x4c
	int 0x21
%else
	; halt in case program is a bootloader.
	jmp $
%endif

print_from_dest:
	push ax
	push bx
.rep:
	lodsb
	cmp al, '$'
	je .end

	mov ah,0xE
	mov bx, 0
	int 0x10
	jmp .rep

.end:
	pop bx
	pop ax
	ret

; Prints 16 bit values in hex
; Input: DX register
printhex:
	pusha
	; print starts from the left
	; prints the higher nibble first then goes right
	; and prints the next nibble and so on.
	mov ah, 0xE	; Bios print call
	mov cx, 4	; loop for 4 times
.rep:
	mov bx, dx
	shr bx, 12
	mov al,[hexchars + bx]
	mov bx, 0
	int 0x10
	
	shl dx, 4
	loop .rep

	popa
	ret

hexchars: db "0123456789ABCDEF"
regs: db "DX: $ SP: $ DS: $ CS: $ SS: $ ES: $ GS: $ FS: $"

%ifdef BIOS
	; Only needed is assembled as a Bootloader.
	times 510 - ($ - $$) db 0
	dw 0xAA55
%endif

