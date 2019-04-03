section .data
	_defDispStr:		db	"Press any key to continue..."
	_defDispStrLen:		equ $-_defDispStr

section .bss 
	_ch:			resb	1	; character returned from read
	_dispStr:		resb	4	; String to be displayed
	_dispStrLen:	resb	2	; Length of the string to be displayed.	

section .text
			global _start

_start:
			mov 	dword [_dispStr],	_defDispStr
			mov		word [_dispStrLen],	_defDispStrLen
			
			call	printStr
			call 	getchar
_end:		
			mov 	eax, 	1
			mov 	ebx, 	0
			int 	80h

getchar:
			pushad 				; push all 8 32 bit registers onto stack
			mov 	eax, 	3	; read system call
			mov 	ebx, 	0	; read from standard int
			mov 	ecx, 	_ch ; store the character in this place 
			mov 	edx, 	1  	; read one character
			int 	80H
			popad				; pop all 8 32 bit registers onto stack
			ret

printStr:
			pushad
			mov 	eax, 	4
			mov 	ebx, 	1
			mov 	ecx, 	[_dispStr]
			mov 	edx, 	[_dispStrLen]	
			int 	80H
			popad
			ret
