; Linux program that shows the startup arguments and the environment variables
; in the stack.

    section .data
EOL:	db 	10

    section .text
	global _start

_start:
	mov ebp, esp		; addressing is done using ebp
	
	; Display arguments
	lea esi, [ebp+4]
	call dispstrlist

	; Display environment variables
	mov eax, [ebp]
	add eax, 2
	lea esi, [ebp+eax*4]
	call dispstrlist

	; exit
	mov eax,1
	int 0x80

; Display strings from a NULL terminated list on the stdout (spearated by \n)
; Input: Location of the first string. 
; returns nothing
dispstrlist:
	lodsd
	cmp eax, 0		; exit if reached end of arguments (noted by NULL byte)
	jz .end
	push eax		; needed for calling strlen & print
	call strlen
	push eax		; length of string for print
	call print		; call print
	add esp, 8		; freeup the stack
	; print the enter
	push EOL
	push dword 1
	call print
	add esp,8		; freeup the stack

	jmp dispstrlist
.end:
	ret

; prints a string in to the stdout
; returns: nothing
; input: location to the string, and length
print:
	push ebp
	mov ebp, esp

.str	equ 12
.len	equ 8
	
	push eax
	push ebx
	push ecx
	push edx

	mov eax, 4		; write system call
	mov ebx, 0		; stdout
	mov ecx, [ebp + .str] 	; string location
	mov edx, [ebp + .len]
	int 0x80
	
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret


; returns the length of a string.
; input: string location in stack.
; returns: length of the string excluding the termination char
strlen:
	push ebp
	mov ebp, esp
.str	equ 8

	push edi
	push ecx

	xor eax,eax		; clear these registers
	mov ecx,0xFFFFFFFF	; max length possible (-1 when negated)
	mov edi,[ebp+.str]	; the location of the string
	repne scasb
	neg ecx			; ecx was decrementing from zero
				; ecx started with -1, and counted passed EOL,
	sub ecx,2		;so we do -2
	mov eax, ecx		; return via eax

	pop ecx
	pop edi
	pop ebp
	ret

