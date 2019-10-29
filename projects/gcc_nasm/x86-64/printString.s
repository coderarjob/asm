
section .text
	global _printstring
	global _strlen

; Prints string using the linux system calls
; Input: 
; 	RDI: Pointer to a ascii string
;	ESI: Length of the string.
; Ouptut:
;	none
_printstring:
	push rax
	push rdi
	push rsi
	push rdx

	xor rdx, rdx
	mov edx, esi	; length
	mov rsi, rdi	; pointer to string

	mov rax, 1
	mov rdi, 0
	syscall
	
	pop rdx
	pop rsi
	pop rdi
	pop rax
	ret

; Returns string length
; Input:
; 	RDI: Pointer to string
; Output:
;	none
_strlen:
	push rcx

	mov rcx, -1
	mov rax, 0
	repne scasb

	neg rcx
	sub rcx, 2

	mov rax, rcx

	pop rcx
	ret

