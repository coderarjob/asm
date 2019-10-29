
	org 0x100

%macro PERSON 2
	push ax
		mov ax, person_size
		mul %2
		mov %1, ax
	pop ax
%endmacro

	; set age for 2nd person
	mov bx, 1
	PERSON bx,bx
	add bx, person.age
	mov [people + bx], byte 10

struc person
	.name resb 11
	.age  resb 1
endstruc

people: times 10 db person_size
