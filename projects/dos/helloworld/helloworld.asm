; Date: Feb 8 2019
; ABOUT:
;     This program is in the format of a DOS COM file.
;     Read more about that in the wikipedia.
; Compile:
;    nasm -f bin -o helloworld.com helloworld.asm
;    no need to link I guess


; The following line is optional, as nasm defaults to 16 bits for bin format.
	BITS 16

; COM files always start at 0100H address. There is no need of relocation, and
; thus no need of a relocating loader/linker

	org	0100H

	mov	bx,	msg 		; Holds the start address of the string
_start_l1:
	mov	dl,	[bx]
	or	dl,	dl
	jz 	_l1_end		; check for end of string. 0 marks EOS
	inc bx			; point to next character

	mov ah,	0002
	int	21H
	jmp	_start_l1
	
_l1_end:
	mov ah,	004CH
	int	21H

; Data must be placed outside of the code.
; So data can be either placed at the very bottom of the file. 
; Or at the top with a jump to the code section before it.
; Note: section .data could also be used, and the result would have been then
; same, assembler will put the data section after the code ends. Just like we
; did here
	msg: db "Hello world",0


