
section .text
	global _start

_start:
	push 10		; this is val 1
	push 12		; this is val 2
	call add

	mov eax, 0
	mov ebx, 1
	int 0x80

add:
	struc add_params, 8
		.val2: resd 1
		.val1: resd 2
	endstruc

	push ebp
	mov ebp, esp
	push ebx
	
	mov eax, [ebp + add_params.val1]
	mov ebx, [ebp + add_params.val2]
	add eax, ebp

	pop ebx
	leave
	ret

		
