; This is the demostration of how function call works in High level languages.
; Function parameters are passed on stack and local variables are also defined
; on the stack. The EBP (Base Pointer) register points to the stack at the
; beginning of the function, and this is used to refrence variabes on stack by
; Effective addressing scheme in x86-64 processers
; The return value from the functions are returned using the EAX register.
;
; Dated: 12/03/2019
; Authors: Arjob Mukherjee (arjobmukherjee@gmail.com)
;

section .text
	global	_start

_start:
	; we are going to pass parameters to ADD and SUB routines via the stack.
	; linux will assign memory for stack and set the ESP register.
	
	;call to ADD

	; push parameters to ADD as DWORD (push accepts word,dword and qword)D
	push 5098
	push 3837
	call ADD
	add	 esp,8

	;call to SUB
	push eax
	push 8802
	call SUB
	add esp, 8

	mov ebx, eax	; store the result in ebx

	;exit (the result will be returned as exit status)
	mov eax,1
	int 0x80

ADD:
	; ebp need to be preserved in case this function is called from inside
	; another fundtion.
	push ebp
	mov	 ebp, esp
	sub  esp, 8		; create space for the two variables (dword in size)
	push edi
	push esi
	mov esi,[ebp+12]
	mov edi,[ebp+8]
	mov [ebp-4],esi
	mov [ebp-8],edi
	mov eax,[ebp-4]
	add eax,[ebp-8]
	pop esi
	pop edi
	add esp,8
	pop ebp
	ret
	
SUB:
	; ebp need to be preserved in case this function is called from inside
	; another fundtion.
	push ebp
	mov ebp,esp
	
	;assign storage for two 32 bit variables
	sub esp,8

	;push other registers that we use in this routine
	push edi
	push esi

	; take the variable values from the stack
	mov edi, [ebp + 12]	; first variable
	mov esi, [ebp + 8]	; second variable

	; store these in the area allocated in the stack for the variables
	mov [ebp - 4], edi	; first variable
	mov [ebp - 8], esi	; second variable

	; perform the sub (first variable - second variable)
	mov eax, [ebp - 4]	; load first variable
	sub eax, [ebp - 8]	; subtract it from the second variable

	pop esi
	pop edi
	add esp,8
	pop ebp
	ret
