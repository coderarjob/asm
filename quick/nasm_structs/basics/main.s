
	ORG 0x100
section .text
	;global _start

_start:
	mov [count], word 5
	lea bx, [ax * sys_proc_item_size]
	mov [bx + sys_proc_item.seg],word 0x800
	mov [bx + sys_proc_item.isloaded],byte 1
	mov ax, 0x4c
	int 0x21

section .data
	struc	sys_proc
	    COUNT resq 1
	    struc sys_proc_item
		    .seg resw 1
		    .isloaded resb 1
	    endstruc
	struc

section .bss
	count	resw 1
	sys_proc_da: resb sys_proc_item_size * 10
