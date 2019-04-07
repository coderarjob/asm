; Dos application that used bios INT 13 calls to read search for a file and
; load it into a buffer and print the buffer on the screen.

	org 0x100

section .data

successstr: 	db	'Success$'
failedstr:  	db	'Failed$'
bootfilename:	db	'OSSPLASHBIN'

BytesPerSector: dw 512
HeadCount:	dw 2
SectorsPerTrack:dw 18
RootDirSectors:	dw 14
RootEntries:	dw 224

filesize:	resd 1
filesector:	resw 1
buffer 		equ 0x400

section .text

%macro	printString 1
	mov ah, 9
	mov dx, %1
	int 0x21
%endmacro

; Reads a sector into a buffer
; Input:
;	Argument 1 - sector number
;	Argument 2 - buffer location
; Output:
;	The flags from INT 13 are preserved.
%macro readSector 2
	push ax
	push bx
	push cx
	push dx

	mov ax, %1
	call csh	; seetup the registers properly for INT 13H

	mov ah, 02	; sector read system call
	mov al, 01	; read one sector
	mov bx, %2
	int 0x13
	
	pop dx
	pop cx
	pop bx
	pop ax
%endmacro
	; ******************************************************
	; MAIN CODE BLOCK
	; ******************************************************

	; reset the floppy drive
	mov ah, 0
	mov dl, 0
	int 0x13
	
	jc failed
	
	; disk reset succeded
	; Read the directory and search for file
searchRoot:
	mov cx, [RootDirSectors]
	mov ax, 19		; root dir starts at sector 19
.readsector:
	readSector ax,buffer

	push cx
	xor bx, bx
.searchRootEntry:
	mov cx, 11
	lea si, [buffer + bx + 32]
	mov di, bootfilename
	repe cmpsb
	je .filefound
	
	; not a match, we go to next entry
	add bx, 64
	cmp bx, 512
	je .filenotfound

	; search this directry entry for the file.
	jnz .searchRootEntry
.filenotfound:
	pop cx
	inc ax	; next sector
	loop .readsector
	printString failedstr
	jmp exit

.filefound:
	pop cx
	; read the file start sector
	mov ax, word [buffer + bx + 32 + 0x1A]
	mov [filesector], ax

	; read file size at 32 bit number
	mov ax, word [buffer + bx + 32 + 0x1C]	; first 16 bits of file size
	mov [filesize], ax

	mov ax, word [buffer + bx + 32 + 0x1E]	; second 16 bits of file size
	mov [filesize+2], ax
	
	; print a message and exit
	printString successstr

	jmp exit

failed:
	; failed
	printString failedstr
	jmp exit

exit:	
	mov ah, 0x4c
	mov al, 0
	int 0x21

%include "readsector.s"

	
