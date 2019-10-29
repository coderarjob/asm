	.file	"main.c"
	.text
#APP
	.code16gcc
	call dosmain
	mov $0x4c, %ah
	int $0x21
#NO_APP
	.globl	printat
	.type	printat, @function
printat:
.LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	.cfi_offset 3, -12
	movzbl	20(%ebp), %ebx
	imull	$80, %ebx, %ebx
	movzbl	16(%ebp), %eax
	addl	%eax, %ebx
	sall	%ebx
	movl	8(%ebp), %eax
	movl	12(%ebp), %edx
#APP
# 17 "main.c" 1
	pushw %gs
	pushw %bx
	movw $0xb800, %bx
	movw %bx, %gs
	popw %bx
	movb %al, %gs:(%bx)
	movb %dl, %gs:1(%bx)
	popw %gs
	
# 0 "" 2
#NO_APP
	popl	%ebx
	.cfi_restore 3
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE0:
	.size	printat, .-printat
	.section	.rodata
	.align 4
.LC0:
	.byte	48
	.byte	49
	.byte	50
	.byte	51
	.byte	52
	.byte	53
	.byte	54
	.byte	55
	.byte	56
	.byte	57
	.byte	65
	.byte	66
	.byte	67
	.byte	68
	.byte	69
	.byte	70
	.text
	.globl	printhex
	.type	printhex, @function
printhex:
.LFB1:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$60, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	8(%ebp), %ebx
	movl	%gs:20, %eax
	movl	%eax, -28(%ebp)
	xorl	%eax, %eax
	leal	-44(%ebp), %edi
	movl	$.LC0, %esi
	movl	$4, %ecx
	rep movsl
	movb	$4, %cl
	movzbl	12(%ebp), %esi
.L4:
	movzbl	row, %eax
	movl	%eax, -60(%ebp)
	movzbl	cols, %eax
	leal	1(%eax), %edi
	movl	%edi, %edx
	movb	%dl, cols
	pushl	-60(%ebp)
	pushl	%eax
	pushl	%esi
	movl	%ebx, %eax
	shrw	$12, %ax
	movzwl	%ax, %eax
	movzbl	-44(%ebp,%eax), %eax
	pushl	%eax
	call	printat
	sall	$4, %ebx
	addl	$16, %esp
	decb	%cl
	jne	.L4
	movl	-28(%ebp), %eax
	xorl	%gs:20, %eax
	je	.L5
	call	__stack_chk_fail
.L5:
	leal	-12(%ebp), %esp
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
.LFE1:
	.size	printhex, .-printhex
	.globl	printstr
	.type	printstr, @function
printstr:
.LFB2:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$12, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	8(%ebp), %ecx
	movzbl	12(%ebp), %ebx
.L10:
	cmpb	$0, (%ecx)
	je	.L13
	movzbl	row, %edi
	movzbl	cols, %eax
	leal	1(%eax), %esi
	movl	%esi, %edx
	movb	%dl, cols
	incl	%ecx
	pushl	%edi
	pushl	%eax
	pushl	%ebx
	movzbl	-1(%ecx), %eax
	pushl	%eax
	call	printat
	addl	$16, %esp
	jmp	.L10
.L13:
	leal	-12(%ebp), %esp
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
.LFE2:
	.size	printstr, .-printstr
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC1:
	.string	"Hello: "
	.text
	.globl	dosmain
	.type	dosmain, @function
dosmain:
.LFB3:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$16, %esp
	movb	$0, cols
	movb	$0, row
	pushl	$15
	pushl	$.LC1
	call	printstr
	popl	%eax
	popl	%edx
	pushl	$14
	pushl	$30974
	call	printhex
	addl	$16, %esp
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE3:
	.size	dosmain, .-dosmain
	.comm	cols,1,1
	.comm	row,1,1
	.ident	"GCC: (GNU) 8.2.1 20181127"
	.section	.note.GNU-stack,"",@progbits
