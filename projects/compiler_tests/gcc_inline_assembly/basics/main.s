	.file	"main.c"
	.code16gcc
	.text
#APP
	call dosmain
	mov $0x4c, %ah
	int $0x21
	
#NO_APP
	.section	.rodata
	.align 4
.LC0:
	.value	1
	.value	2
	.value	3
	.value	4
	.value	5
	.value	6
	.value	7
	.text
	.globl	dosmain
	.type	dosmain, @function
dosmain:
.LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$16, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	leal	-26(%ebp), %eax
	movl	$.LC0, %ebx
	movl	$14, %edx
	movl	%eax, %edi
	movl	%ebx, %esi
	movl	%edx, %ecx
	rep movsb
	nop
	addl	$16, %esp
	popl	%ebx
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE0:
	.size	dosmain, .-dosmain
	.ident	"GCC: (GNU) 9.1.0"
	.section	.note.GNU-stack,"",@progbits
