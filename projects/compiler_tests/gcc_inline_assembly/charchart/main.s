	.file	"main.c"
	.code16gcc
	.text
#APP
	call main
	movb $0x4c, %ah
	int $0x21
	
#NO_APP
	.globl	screenpos
	.bss
	.align 2
	.type	screenpos, @object
	.size	screenpos, 2
screenpos:
	.zero	2
	.globl	attr
	.data
	.type	attr, @object
	.size	attr, 1
attr:
	.byte	15
	.globl	s
	.align 4
	.type	s, @object
	.size	s, 4
s:
	.ascii	"0000"
	.globl	ch
	.bss
	.type	ch, @object
	.size	ch, 1
ch:
	.zero	1
	.text
	.globl	write
	.type	write, @function
write:
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
	subl	$4, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	12(%ebp), %eax
	movw	%ax, -16(%ebp)
	movw	screenpos, %di
	movb	attr, %al
	movl	8(%ebp), %esi
	movl	-16(%ebp), %edx
	movl	%edx, %ecx
	movb	%al, %dl
#APP
# 26 "main.c" 1
	push %es
	mov $0xb800, %bx
	mov %bx, %es
	repeat:
	lodsb
	mov %al, %es:(%di)
	mov %dl, %es:1(%di)
	add $2, %di
	loop repeat
	pop %es
	
# 0 "" 2
#NO_APP
	movl	%edi, %edx
	movw	%dx, screenpos
	nop
	addl	$4, %esp
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
	.size	write, .-write
	.globl	strlen
	.type	strlen, @function
strlen:
.LFB1:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%ebx
	subl	$16, %esp
	.cfi_offset 7, -12
	.cfi_offset 3, -16
	movw	$-1, -10(%ebp)
	movw	-10(%ebp), %ax
	movl	8(%ebp), %ebx
	movl	%eax, %edx
	movl	%edx, %ecx
	movl	%ebx, %edi
#APP
# 46 "main.c" 1
	mov $0, %al
	repne scasb
	neg %cx
	
# 0 "" 2
#NO_APP
	movl	%ecx, %edx
	movw	%dx, -10(%ebp)
	subw	$2, -10(%ebp)
	movw	-10(%ebp), %ax
	addl	$16, %esp
	popl	%ebx
	.cfi_restore 3
	popl	%edi
	.cfi_restore 7
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE1:
	.size	strlen, .-strlen
	.section	.rodata
.LC0:
	.ascii	"0123456789ABCDEF"
	.text
	.globl	printhex
	.type	printhex, @function
printhex:
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
	subl	$40, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	8(%ebp), %eax
	movl	12(%ebp), %edx
	movw	%ax, -48(%ebp)
	movb	%dl, %al
	movb	%al, -52(%ebp)
	leal	-32(%ebp), %eax
	movl	$.LC0, %ebx
	movl	$4, %edx
	movl	%eax, %edi
	movl	%ebx, %esi
	movl	%edx, %ecx
	rep movsl
	movl	$0, -16(%ebp)
	jmp	.L5
.L6:
	movl	-48(%ebp), %eax
	shrw	$12, %ax
	movzwl	%ax, %eax
	movb	-32(%ebp,%eax), %al
	movb	%al, %dl
	movl	-16(%ebp), %eax
	addl	$s, %eax
	movb	%dl, (%eax)
	incl	-16(%ebp)
	salw	$4, -48(%ebp)
.L5:
	cmpl	$3, -16(%ebp)
	jle	.L6
	pushl	$4
	pushl	$s
	call	write
	addl	$8, %esp
	nop
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
	.size	printhex, .-printhex
	.globl	main
	.type	main, @function
main:
.LFB3:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	$2
	pushl	$61355
	call	printhex
	addl	$8, %esp
	nop
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE3:
	.size	main, .-main
	.ident	"GCC: (GNU) 9.1.0"
	.section	.note.GNU-stack,"",@progbits
