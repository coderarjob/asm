; Reads characters from stdin into a buffer and writes it back out to stdout,
; until End of File (EOF) is detected.
; This is kind of an echo program, it will repeat what you say to it.
;
; Dated: 8/02/2019
;
; Compile:
; 	nasm -f elf32 s.asm -o s.o
;	ld -m elf_i386 s.o -o s
;

section .bss ;align = 0
	bufferlength:	equ		1024
	buffer: 		resb	bufferlength
	buffer_bcount:	resw	1

section .text
	global _start

_start:
	call	read					; read into the buffer from stdin
	cmp 	[buffer_bcount],word 0 	; we read zero bytes (EOF)
	je 		end						; End of file was reached, so we exit
	call	convert					; convert upper case to lower case
	call 	write					; write the read bytes to stdout
	jmp 	_start					; repeat again, until EOF
end:
	;exit
	mov 	eax,	1H
	mov 	ebx,	0
	int 	80H

convert:
	push 	eax
	push 	ebx
	push 	ecx

	mov 	bx, 	[buffer_bcount]	; mov ebx, word [buffer_bcount] error???
	mov 	eax, 	buffer
	
	dec bx
.loop_start:
	mov 	cl,		[eax + ebx]
	cmp 	cl,		'A'
	jb 		.loop_next
	cmp 	cl,		'Z'
	ja 		.loop_next
	
	; convert upper to lower (now that we know that the byte represents an
	; upper case letter
	add 	[eax+ebx],	byte 0x20

.loop_next:
	cmp		bx, 0
	je		.end
	dec 	bx
	jmp 	.loop_start

.end:
	pop 	ecx
	pop 	ebx
	pop 	eax
	ret

read:
	push 	eax
	push 	ebx
	push 	ecx
	push 	edx

	mov		eax, 	0x3	; read system call
	mov 	ebx, 	0x0	; read from the standard input
	mov 	ecx, 	buffer	; store in the buffer
	mov 	edx, 	bufferlength
	int 	80H

	; the number of bytes read in returned in eax
	; we store this number to memory from the register
	; for use by the write subroutine
	mov 	[buffer_bcount],	eax

	pop 	edx
	pop 	ecx
	pop 	ebx
	pop 	eax
	ret

write:
	push 	eax	
	push 	ebx
	push 	ecx
	push 	edx
	
	mov		eax, 	0x4	; wtite system call
	mov 	ebx, 	0x1	; write to standard output
	mov 	ecx, 	buffer	; store in the buffer
	mov 	edx, 	[buffer_bcount]
	int 	80H

	pop 	edx
	pop 	ecx
	pop 	ebx
	pop 	eax
	ret
