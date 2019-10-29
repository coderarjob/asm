; Demostrates the use of CMPS instruction in comparing strings.
; This program takes an argument, if it matches the VALIDUSER, then
; it prints a valid message, otherwise prints invalid message.

section .text
	global _start

_start:
	; CPMSB matches bytes in memory locations held in ESI and EDI
	; registers. This instruction also advances (DF = 0) these registers
	; REPE repeats the CMPSB instruction while the two memory locations
	; match and ECX register is not zero

	mov esi, [esp + 8]
	mov edi, validuser
	mov ecx, validuser_len	; used by the repe prefix
	repe cmpsb
	
	; print message
	cmp ecx, 0
	ja .invalid

	; ECX = 0, valid user (string matches)
	mov ecx, uservalid
	mov edx, uservalid_len
	jmp .cont

.invalid:
	; String did not match
	mov ecx, userinvalid	
	mov edx, userinvalid_len
.cont:
	; prints a message on the screen
	mov eax, 4		; print system call
	mov ebx, 0		; stdout
	int 0x80

	; exit program
	mov eax, 1
	mov ebx, 0
	int 0x80
	
section .data
validuser: db "arjob"
validuser_len: equ $ - validuser

userinvalid: db "User is invalid",10
userinvalid_len: equ $ - userinvalid

uservalid: db "Welcome Arjob Mukherjee",10
uservalid_len: equ $ - uservalid

