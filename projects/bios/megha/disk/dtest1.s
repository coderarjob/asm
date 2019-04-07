; will be a dos application that will demo INT 13H operations

	org 0x100
	
	; reset the floppy drive
	mov ah, 0
	mov dl, 0
	int 0x13
	
	jc failed
	
	; disk reset succeded
	mov ah, 9
	mov dx, successstr
	int 0x21

	; read logical sector starting with location in AX
	mov ax, 34
	mov bx, buffer
	call csh
	
	mov ah, 2
	mov al, 1
	int 0x13

	jc failed

	; disk operation success
	mov ah, 9
	mov dx, successstr
	int 0x21
	jmp exit

failed:
	; failed
	mov ah, 9
	mov dx,failedstr
	int 0x21

	jmp exit

exit:	
	mov ah, 0x4c
	mov al, 0
	int 0x21

; Calculates the cylinder/track, circular sector and head for INT 0x14
; Input: 
;	AX - Sector number
; Output:
;	ch - Cylinder number
; 	dl - sector number (1 - 63)
;	dh - head number
csh:
	push ax
	push bx

	; disk sector (circular sector)
	xor dx, dx	; clear dx again, for second div
	div word [SectorsPerTrack]
	add dx, 1	; sector starts from 1 in INT 13
	mov bl, dl	; save the sector in BL

	; track with more than one head
	xor dx, dx
	div word [HeadCount]
	mov ch, al	; cylinder
	mov cl, bl	; sector
	mov dh, dl	; head
	mov dl, 0	; disk 0

	pop bx
	pop ax
	ret

successstr: db	'Success$'
failedstr:  db	'Failed$'

BytesPerSector: dw 512
HeadCount:	dw 2
SectorsPerTrack:dw 18

buffer:	resb 512
