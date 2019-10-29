bits 16

; glb ch : char
section .bss
	global	_ch
_ch:
	resb	1

; glb main : () void
section .text
	global	_main
_main:
	push	ebp
	movzx	ebp, sp
	 sub	sp,         12
; loc     i : (@-4) : int
; RPN'ized expression: "i 0 = "
; Expanded expression: "(@-4) 0 =(4) "
; Fused expression:    "=(204) *(@-4) 0 "
	mov	eax, 0
	mov	[bp-4], eax

section .data
L3:
; RPN'ized expression: "48 "
; Expanded expression: "48 "
; Expression value: 48
	db	48
; RPN'ized expression: "49 "
; Expanded expression: "49 "
; Expression value: 49
	db	49
; RPN'ized expression: "50 "
; Expanded expression: "50 "
; Expression value: 50
	db	50
; RPN'ized expression: "51 "
; Expanded expression: "51 "
; Expression value: 51
	db	51
; RPN'ized expression: "52 "
; Expanded expression: "52 "
; Expression value: 52
	db	52
; RPN'ized expression: "53 "
; Expanded expression: "53 "
; Expression value: 53
	db	53
; RPN'ized expression: "54 "
; Expanded expression: "54 "
; Expression value: 54
	db	54

section .text
; loc     array : (@-12) : [7u] char
; =
; Fused expression:    "( (@-12) , L3 , 7u , L4 )12 "
	xor	eax, eax
	mov	ax, ss
	shl	eax, 4
	lea	eax, [ebp+eax-12]
	push	eax
section .relod
	dd	L5
section .text
	db	0x66, 0x68
L5:
	dd	L3
	push	dword 7
	db	0x9A
section .relot
	dd	L6
section .text
L6:
	dd	L4
	sub	sp, -12
; RPN'ized expression: "ch array i + *u = "
; Expanded expression: "ch (@-12) (@-4) *(4) + *(-1) =(-1) "
; Fused expression:    "ch push-ax + (@-12) *(@-4) =(119) **sp *ax "
section .relod
	dd	L7
section .text
	db	0x66, 0xB8
L7:
	dd	_ch
	push	eax
	xor	eax, eax
	mov	ax, ss
	shl	eax, 4
	lea	eax, [ebp+eax-12]
	add	eax, [bp-4]
	mov	ebx, eax
	mov	esi, ebx
	ror	esi, 4
	mov	ds, si
	shr	esi, 28
	mov	al, [si]
	movsx	eax, al
	pop	ebx
	mov	esi, ebx
	ror	esi, 4
	mov	ds, si
	shr	esi, 28
	mov	[si], al
	movsx	eax, al
; Fused expression:    "0  "
	mov	eax, 0
L1:
	db	0x66
	leave
	retf
L8:

section .fxnsz noalloc
	dd	L8 - _main

section .text
L4:
	push	ebp
	movzx	ebp, sp
	;sub	sp,          0
	mov	edi, [bp+16]
	ror	edi, 4
	mov	es, di
	shr	edi, 28
	mov	esi, [bp+12]
	ror	esi, 4
	mov	ds, si
	shr	esi, 28
	mov	ebx, [bp+8]
	cld
L9:
	mov	ecx, 32768
	cmp	ebx, ecx
	jc	L10
	sub	ebx, ecx
	rep	movsb
	and	di, 15
	mov	ax, es
	add	ax, 2048
	mov	es, ax
	and	si, 15
	mov	ax, ds
	add	ax, 2048
	mov	ds, ax
	jmp	L9
L10:
	mov	cx, bx
	rep	movsb
	mov	eax, [bp+16]
	db	0x66
	leave
	retf



; Syntax/declaration table/stack:
; Bytes used: 85/15360


; Macro table:
; Macro __SMALLER_C__ = `0x0100`
; Macro __SMALLER_C_32__ = ``
; Macro __HUGE__ = ``
; Macro __SMALLER_C_SCHAR__ = ``
; Macro __SMALLER_C_UWCHAR__ = ``
; Macro __SMALLER_C_WCHAR16__ = ``
; Bytes used: 121/5120


; Identifier table:
; Ident 
; Ident __floatsisf
; Ident __floatunsisf
; Ident __fixsfsi
; Ident __fixunssfsi
; Ident __addsf3
; Ident __subsf3
; Ident __negsf2
; Ident __mulsf3
; Ident __divsf3
; Ident __lesf2
; Ident __gesf2
; Ident ch
; Ident main
; Bytes used: 133/5632

; Next label number: 11
; Compilation succeeded.
