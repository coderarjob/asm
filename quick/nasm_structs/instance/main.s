


	org 0x100

struc person
	.iden resw 1
	.name resb 10
endstruc

nop
nop
nop

person1:
	istruc person
		at person.iden, dw 0xE01A
		at person.name, db 'Arjob',0
	iend

nop
nop
nop



