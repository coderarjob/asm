; Date: Feb 8 2019
; ABOUT:
;     This program is in the format of a DOS COM file.
;     Read more about that in the wikipedia.
; DOS INTERRUPT:
;	  INT 21,09 - Print string
;     AH = 09
;     DS:DX = pointer to string ending in "$"
; Compile:
;    nasm -f bin -o helloworld.com helloworld.asm
;    no need to link I guess


; The following line is optional, as nasm deafult to 16 bits for bin format.
	BITS 16

section .data
	msg: db "Hello world$" 	; string ends with $ (weird DOS times)

section .text

; COM files always start at 0100H address. There is no need of relocation, and
; thus no need of a relocating loader/linker

	org 0100H

	mov ah,09		; call the print string routine
	mov dx,msg		; the message is pointed by DS:DX
	int 21H

_l1_end:
	mov ah, 04CH
	int 21H

