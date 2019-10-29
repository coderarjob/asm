
	global _exit
_exit:
	mov eax, 0x4c
	mov ebx, 0
	int 0x21
