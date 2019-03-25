O_RO: equ 00
O_RW: equ 02

section .bss
filedata:	resb 512

section .data
filename: db "./prog1.bin",0

section .text
	global _start

_start:
	; open file 
	mov eax,5			; open system call
	mov ebx,filename
	mov ecx,O_RO
	int 80H
	mov ebx,eax			; store the returned fd to ebx (used in read & write)
	
	;read the file to memory
	mov eax,3			; read system call
	mov ecx,filedata
	mov edx,512
	int 80H
	
	; execute the bytes just loaded into memory 
	; loaded program prints a string to a file.
	push filedata		
	mov ebp,esp
	call filedata		; call the program in loaded memory

.end:
	mov eax,1
	mov ebx,0
	int 80H

