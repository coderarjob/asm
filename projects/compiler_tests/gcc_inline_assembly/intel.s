	.file	"intel_syntax.c"
	.intel_syntax noprefix
	.text
	.section	.rodata
.LC0:
	.string	"%u\n"
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	mov	rbp, rsp
	.cfi_def_cfa_register 6
	sub	rsp, 32
	mov	rax, QWORD PTR fs:40
	mov	QWORD PTR -8[rbp], rax
	xor	eax, eax
	mov	DWORD PTR -24[rbp], 9
	mov	DWORD PTR -20[rbp], 1
	mov	DWORD PTR -16[rbp], 3
	mov	DWORD PTR -12[rbp], 4
	lea	rdx, -20[rbp]
#APP
# 7 "intel_syntax.c" 1
	mov eax, 7;mov dword ptr [rdx],eax;
# 0 "" 2
#NO_APP
	mov	DWORD PTR -28[rbp], 0
	jmp	.L2
.L3:
	mov	eax, DWORD PTR -28[rbp]
	cdqe
	mov	eax, DWORD PTR -20[rbp+rax*4]
	mov	esi, eax
	lea	rdi, .LC0[rip]
	mov	eax, 0
	call	printf@PLT
	add	DWORD PTR -28[rbp], 1
.L2:
	cmp	DWORD PTR -28[rbp], 2
	jle	.L3
	mov	eax, DWORD PTR -24[rbp]
	mov	rcx, QWORD PTR -8[rbp]
	xor	rcx, QWORD PTR fs:40
	je	.L5
	call	__stack_chk_fail@PLT
.L5:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.ident	"GCC: (GNU) 8.2.1 20181127"
	.section	.note.GNU-stack,"",@progbits
