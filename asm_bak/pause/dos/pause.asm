; The classic PAUSE.COM program in DOS
; Date: 10/03/2019
; Author: Arjob Mukherjee (arjobmukherjee@gmail.com)
;
;

BITS 16

org 0x100
section .bss
	_ch:		resb	1	; stores the read character
	message:	resb	2	; stores the address of the string

section .data
	def_message:	db	'Pause any key to continue.',10,13,'$'

section .text
	mov	 word [message], def_message	; sets message to the default string
	call printStr
	call getchar

_exit:
	mov ah,00
	int 0x21

getchar:
	pusha
	mov ah, 0x7
	int 0x21
	mov [_ch], al		; return char will have no use in pause
	popa
	ret

printStr:
	pusha
	mov ah, 0x9
	mov dx,	[message]
	;mov dx, def_message
	int 0x21
	popa
	ret

db '$'
