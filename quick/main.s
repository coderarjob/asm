
	org 0x100
	jmp near _main
_sub:
	ret

_main:
	push byte 8
	call far [CodeSeg] 


CodeSeg: dw 0x103
	 dw 0x74c
