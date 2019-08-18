; : This program will demostrate setting up of the 8254 PIT and using IRQ0
; routine. It also demostrates the use of 8254 to produce sound though PC
; speaker.

;%define BIOS

%ifdef BIOS
	ORG 0x7c00
	%include "../bpb.s"
%else
	ORG 0x100
%endif

boot_main:
	; Setup PIT Channel 0 to produce freq 36 Hz.
	mov al, 0x34 ; Counter 0 in mode 2, double byte

	mov ax, 0x8157
	out 0x40, al
	mov al, ah
	out 0x40, al
	; -------------------------------------------------

	; Setup 8254 Channel 2 to output ~200 Hz square wave (mode 3)

	; Sound cannot be in mode 2, as the duty cycle is too high, 8254 out is 
	; almost always HIGH in Mode 2, with one cycle LOW, when the counter 
	; reaches to 1

	mov al, 0xB6	; Counter 2, in mode 3, double byte 
	out 0x43, al

	mov ax, 0x1748	; 200 Hz
	out 0x42, al
	mov al, ah
	out 0x42, al

	; Turn on GATE for Counter 2 of 8254
	in al, 0x61
	or al, 3
	out 0x61, al
	; -------------------------------------------------

	; install IRQ0
	xor ax, ax
	mov es, ax
	mov [es:8*4],word ir1_0
	mov [es:8*4+2], cs
	; -------------------------------------------------

	; Display the count
	mov ax, 0xb800
	mov es, ax
	mov si, 0
again:
	mov al, [char]
	mov [es:si],al
	mov [es:si+1],byte 0xE
	jmp again
	; -------------------------------------------------

ir1_0:
	push ax
	cmp [limit], word 0x0
	jnz .cont
	
	mov [limit],word RELOAD_VALUE
	inc byte [char]

.cont:
	dec word [limit]

	; Send a EOI to PIC
	mov al, 0x20
	out 0x20,al
	pop ax
	iret
	; -------------------------------------------------

char: db '0'
limit: dw RELOAD_VALUE
RELOAD_VALUE: equ  0x12

%ifdef BIOS
	times 510 - ($-$$) db 0
	dw 0xAA55
%endif
