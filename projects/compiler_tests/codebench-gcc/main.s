	.arch i8086,jumps
	.code16
	.att_syntax prefix
#NO_APP
#APP
	.intel_syntax noprefix
	call main
	jmp .
	
#NO_APP
	.global	screenpos
	.bss
	.p2align	1
	.type	screenpos, @object
	.size	screenpos, 2
screenpos:
	.skip	2,0
	.global	attr
	.data
	.type	attr, @object
	.size	attr, 1
attr:
	.byte	15
	.global	ch
	.bss
	.p2align	0
	.type	ch, @object
	.size	ch, 1
ch:
	.skip	1,0
	.text
	.global	write
	.type	write, @function
write:
	pushw	%bp
	movw	%sp,	%bp
	nop
	popw	%bp
	ret
	.size	write, .-write
	.global	main
	.type	main, @function
main:
	pushw	%si
	pushw	%di
	pushw	%bp
	movw	%sp,	%bp
	subw	$18,	%sp
	movb	$48,	-17(%bp)
	movb	$49,	-16(%bp)
	movb	$50,	-15(%bp)
	movb	$51,	-14(%bp)
	movb	$52,	-13(%bp)
	movb	$53,	-12(%bp)
	movb	$54,	-11(%bp)
	movb	$55,	-10(%bp)
	movb	$56,	-9(%bp)
	movb	$57,	-8(%bp)
	movb	$65,	-7(%bp)
	movb	$66,	-6(%bp)
	movb	$67,	-5(%bp)
	movb	$68,	-4(%bp)
	movb	$69,	-3(%bp)
	movb	$70,	-2(%bp)
	movb	$0,	-1(%bp)
	movb	-1(%bp),	%al
	xorb	%ah,	%ah
	movw	%ax,	%di
	movw	%bp,	%si
	movw	%di,	%bx
	movb	-17(%bx,%si),	%al
	movb	%al,	ch
	movw	$1,	%ax
	pushw	%ax
	movw	$ch,	%ax
	pushw	%ax
	call	write
	addw	$4,	%sp
	nop
	movw	%bp,	%sp
	popw	%bp
	popw	%di
	popw	%si
	ret
	.size	main, .-main
	.ident	"GCC: (Sourcery CodeBench Lite 2016.11-64) 6.2.0"
