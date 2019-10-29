section .bss 
	_ch:			resb	1	; character returned from read

section .text
			global _start

_start:
			call 	getchar		; pause for some character

			; print contents of ds register
			mov 	word [_ch], ds
			call	putchar
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

putchar:
			pushad
			mov 	eax, 	4
			mov 	ebx, 	1
			mov 	ecx, 	_ch
			mov 	edx, 	1	
			int 	80H
			popad
			ret
