	.file	"pointer.c"
	.text
#APP
	.code16gcc;call dosmain;mov $0x4c, %ah;int $0x21;
#NO_APP
	.globl	print
	.type	print, @function
print:
.LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	movl	8(%ebp), %edx
#APP
# 10 "pointer.c" 1
	mov $02, %ah;int $0x21;
# 0 "" 2
#NO_APP
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE0:
	.size	print, .-print
	.globl	print2
	.type	print2, @function
print2:
.LFB1:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	.cfi_offset 3, -12
	movl	8(%ebp), %eax
#APP
# 21 "pointer.c" 1
	pushw %ds
movw $0xb800,%bx
movw %bx, %ds
movb %al, %bh
movb %al, 0
movb $0xE,1
popw %ds

# 0 "" 2
#NO_APP
	popl	%ebx
	.cfi_restore 3
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE1:
	.size	print2, .-print2
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
	subl	$20, %esp
	pushl	$66
	call	print2
	addl	$16, %esp
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE2:
	.size	dosmain, .-dosmain
	.ident	"GCC: (GNU) 8.2.1 20181127"
	.section	.note.GNU-stack,"",@progbits
