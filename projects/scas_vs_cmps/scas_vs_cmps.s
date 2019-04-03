; This will be a little demostration for SCAS vs CMPS instructions
; It is designed to be work in gdb (and looking at registers manually)
; Note: Running this application like normal will SEGFAULT.

section .data
	mem1:	db	'12'
	mem2	db	'13'
	text:	db	'aA'

section .text
	global _start
_start:

; SCAS test
; SCASB matches the AL with the byte at es:edi

	mov edi, text
	mov al, 'a'
	scasb		; will succeed (ZF = 1) and incremnt EDI
	scasb		; will fail (ZF = 0) and increment EDI

; CMPS test
; CMPSB matches byte at location DS:ESI and ES:EDI and sets flags

	mov edi, mem1
	mov esi, mem2

	cmpsb		; will pass (ZF = 1) and increment EDI, ESI
	cmpsb		; will fail (ZF = 0) and increment EDI, ESI

	nop

