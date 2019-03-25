[bits 32]

%macro relmov 2
	mov %1, [ebp]
	add %1,%2
%endmacro

section .data
msg:	db "Hello world, I am Zorg!",10
msglen:	equ $-msg

section .text
	; Writes string to the screen
	mov ebx,0			; write to the stdout
	relmov ecx,msg		; relative addressing to load msg+[relm] to ebx
	mov edx,msglen		; bytes to write
	mov eax,4			; write system call
	int 80H
	
	ret


