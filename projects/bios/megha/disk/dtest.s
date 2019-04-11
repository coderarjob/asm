; Dos application that used bios INT 13 calls to read search for a file and
; load it into a buffer and print the buffer on the screen.

	org 0x100

section .data

successstr: 	db	'Success$'
failedstr:  	db	'Failed$'
;bootfilename:	db	'OSSPLASHBIN'
bootfilename:	db	'FOO     TXT'

ReservedSector: dw 1
BytesPerSector: dw 512
HeadCount:	dw 2
SectorsPerTrack:dw 18
RootDirSectors:	dw 14
RootEntries:	dw 224

filesize:	resd 1
filesector:	resw 1
filereqsize:	dw   20
fileremsize	resw 1

buffer 		equ 0x400
obuffer		equ 0x600

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
	pusha		; I used push and pop a just to same some memory

	mov ax, %1
	call csh	; seetup the registers properly for INT 13H

	mov ah, 02	; sector read system call
	mov al, 01	; read one sector
	mov bx, %2
	int 0x13

	popa
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
	; read the following sector
	;mov word [filesector], 0x4
	;mov dword [filesize], 0x40
	;jmp readfiledata

	; switch to 0x13 mode
	;mov ah, 0
	;mov al, 0x13
	;int 0x10

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
	lea si, [buffer + bx]
	mov di, bootfilename
	repe cmpsb
	je .filefound
	
	; not a match, we go to next entry
	;add bx, 64
	add bx, 32
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
	mov ax, word [buffer + bx + 0x1A]
	mov [filesector], ax

	; read file size at 32 bit number
	mov ax, word [buffer + bx + 0x1C]	; first 16 bits of file size
	mov [filesize], ax

	mov ax, word [buffer + bx + 0x1E]	; second 16 bits of file size
	mov [filesize+2], ax
	
	; print a message and exit
	printString successstr

readfiledata:
	; set the requested size of the file = file size if the former is
	; greater.
	; TODO: do 32 bit compare
	mov ax, [filesize]
	cmp [filereqsize], ax		
	jbe  .lesser			; requested size =< filesize

	; requested size > file size
	mov [filereqsize], ax		; requested size = filesize 
.lesser:
	; keep the requested size as backup for later
	; needed for calculation of total bytes read
	mov ax, [filereqsize]
	mov [fileremsize], ax		; reading will continue while 
					; remaining size is > 0
	; setup the counter register
.repeat:
	cmp [fileremsize], word 0
	je .readFileEnd

	cmp [fileremsize],word 512
	ja .greater

	; file remaining size >= 512
	mov cx, [fileremsize]
	jmp .readDataSector

.greater:
	mov cx, 512

.readDataSector:
	mov ax, [filesector]
	add ax, 31			; sector = sector -2 + 33
	readSector ax, buffer		; read sector to internal buffer

	; we copy as many bytes in the CX register from the internal buffer to
	; the output buffer
	mov dx, cx
	cld				; set direcection flag = 0 (increment)
	mov si, buffer
	mov di, obuffer
	rep movsb

	; update remaining size variable.
	sub dx, cx			; number of bytes read in dx
	sub word [fileremsize], dx	; remaining = remaining - bytes read
.getNextSector:
	; now we get the next sector to read
	mov ax, [filesector]
	mov bx, ax
	shr ax, 1
	add ax, bx			; [filesector] * 3/2

	; we normalize the byte location in ax.
	; example: byte 513 in FAT table, is byte 1 of sector 2 of disk
	xor dx, dx
	div word [BytesPerSector]
	
	; dx contains the normalized byte to be read from sector in ax
	add ax, [ReservedSector]	; take into account reserved sector

	; read the sector (containing FAT entry)
	readSector ax, buffer

	; read the word located at DX location
	mov bx, dx			; DX cannot be used in effective
					; addtessing. So we use BX
	mov ax, [buffer + bx]

	; check if byte location is odd or even
	test word [filesector], 0x1
	jnz .odd
	
	; Byte location is even
	and ax, 0xFFF
	jmp .checkForLastSector
.odd:
	shr ax, 4
.checkForLastSector:
	cmp ax, 0xFFF
	mov [filesector], ax		; save the sector to the 'filesector'
					; variable, so that we read that sector
					; after we jump
	jnz .repeat
.readFileEnd:

	; reading is complete (print the file content)
	mov cx, [filereqsize]
	mov si, 0x600
	mov ax, 0xB800
	mov es, ax
	mov di, 0
.rep:
	lodsb
	mov [es:di],al
	mov [es:di+1], byte 0x4
	add di, 2
	loop .rep

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

	
