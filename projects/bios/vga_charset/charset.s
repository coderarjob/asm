; DOS program that displays the characterset for the selected VGA text mode.
; Dated: 27th March 2019
; Authors: Arjob Mukherjee (mukherjeearjob@gmail.com)

;org 0x100
	; Following is the Bios Parameter Block
	jmp boot_start

	OEMLabel		db "ARJOBOOT"	; Disk label
	BytesPerSector		dw 512		; Bytes per sector
	SectorsPerCluster	db 1		; Sectors per cluster
	ReservedForBoot		dw 1		; Reserved sectors for boot record
	NumberOfFats		db 2		; Number of copies of the FAT
	RootDirEntries		dw 224		; Number of entries in root dir
						; (224 * 32 = 7168 = 14 sectors to read)
	LogicalSectors		dw 2880		; Number of logical sectors
	MediumByte		db 0F0h		; Medium descriptor byte
	SectorsPerFat		dw 9		; Sectors per FAT
	SectorsPerTrack		dw 18		; Sectors per track (36/cylinder)
	Sides			dw 2		; Number of sides/heads
	HiddenSectors		dd 0		; Number of hidden sectors
	LargeSectors		dd 0		; Number of LBA sectors
	DriveNo			dw 0		; Drive No: 0
	Signature		db 41		; Drive signature: 41 for floppy
	VolumeID		dd 00000000h	; Volume ID: any number
	VolumeLabel		db "ARJOBOS    "; Volume Label: any 11 chars
	FileSystem		db "FAT12   "	; File system type: don't change!

boot_start:
	; we will use mode 0x3, that is 80x25 16 color vga text display
	mov ah,00
	mov al,03
	int 0x10
	

	; setup the segment register
	mov bx, 0xB800
	mov gs, bx
	mov bx, 0x7C0
	mov ds,bx
build_headers:
	;print the header in the first row of every column and row
	mov bx, 166		; used in headers in every column
	mov di, 322		; used in headers in every row
	mov si, headers
.loop:
	lodsb
	cmp ax,0
	je .end
	; top header
	mov [gs:bx],ax
	mov [gs:bx+1], byte 0xA
	add bx,4
	
	; left header
	mov [gs:di],ax
	mov [gs:di+1],byte 0xA
	add di,160

	jmp .loop
.end:
	; wait for key press
	mov ah, 0x0
	int 16h

	; clear the display
	mov ah,0
	mov al,03
	int 0x10

put_chars:
	mov bx,326
	mov ax,0
.loop:
	mov [gs:bx],ax
	mov [gs:bx+1],byte 0xF
	add bx,4
	cmp ax,255
	jz end
	inc ax
	test ax,15
	jnz .loop
	add bx,96 		; 159 - 70 bytes + 1 + 6 = 96
	jmp .loop

end:
	; wait for keystroke
	mov ah,00
	int 0x16
	
	;switch to a 8x8 font
	mov ax, 0x1112
	mov bl,0
	int 10h

	jmp $

headers:	db	'0123456789ABCDEF',0

times (510 - ($-$$)) db 0
dw 0xAA55
