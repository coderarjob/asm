	.file	"main.c"
	.code16gcc
	.text
#APP
	call dosmain
	mov $0x4c, %ah
	int $0x21
	
#NO_APP
	.globl	foo
	.type	foo, @function
foo:
.LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	movl	8(%ebp), %eax
	movw	$18, (%eax)
	nop
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE0:
	.size	foo, .-foo
	.globl	add
	.type	add, @function
add:
.LFB1:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	movl	8(%ebp), %edx
	movl	12(%ebp), %eax
	movw	%dx, -4(%ebp)
	movw	%ax, -8(%ebp)
	movl	-4(%ebp), %edx
	movl	-8(%ebp), %eax
	addl	%edx, %eax
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE1:
	.size	add, .-add
	.globl	dosmain
	.type	dosmain, @function
dosmain:
.LFB2:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$16, %esp
	pushl	$3
	pushl	$2
	call	add
	addl	$8, %esp
	movw	%ax, -2(%ebp)
	movw	$19, -10(%ebp)
	leal	-10(%ebp), %eax
	movl	%eax, -8(%ebp)
	leal	-10(%ebp), %eax
	pushl	%eax
	call	foo
	addl	$4, %esp
	nop
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE2:
	.size	dosmain, .-dosmain
	.ident	"GCC: (GNU) 8.2.1 20181127"
	.section	.note.GNU-stack,"",@progbits
