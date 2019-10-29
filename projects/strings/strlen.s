; This linux program returns the string length. 
; Implementation is based on the SCASB and LOOP instruction.

    global _start
section .text

_start:
	jmp imp2

; Implementation 1: LOOP
; LOOPNZ branches as long as ECX register holds a value that is not zero
; and the ZF flag is NOT SET.
; LODSB loads a byte pointed to by the memory address in DS:ESI into AL, and
; advances the ESI register.
imp1:
	xor eax, eax
	mov ecx, 0xFFFF
	mov esi, string1
.rep1:
	lodsb
	cmp eax, 0
	loopnz .rep1

; Implementation 2: Using SCASB
; SCASB instruction compares the byte in AL with the byte in ES:EDI, and sets
; the ZF flag accordingly
; The REPNE instruction counts down ECX register (as long as it is not zero)
; and the ZF flag is NOT SET.
imp2:
	mov cx, 0xFFFF
	mov ax, 0
	mov edi, string1
	repne scasb

	;exit dos with the length
	neg ecx
	sub ecx, 2
	jmp end

end:
	mov ebx, ecx
	mov eax, 1
	int 0x80


section .data
string1: db "Arjob",0
