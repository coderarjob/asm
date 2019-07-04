; MEGHA BOOT LOADER
; Version: 0.02
;
; Contains FAT12 driver, that reads a bitmap file from the disk to a buffer and
; prints the buffer to the screen.
;
; Changes from version 0.01 (4th July 2019)
; -------------------------
; * Removed the 'Welcome' message. Directly boots into the splashscreen now.
; * Removed 'filereqsize', 'filesize' (these were not really needed, we want to
;   load the whole file, so stating required size was useless).
; * Changed 'osegoffset' from EQU to RESW.
; * Resulted in reducing the file size from 503 bytes to 430 bytes in v0.02.

	org 0x7C00
	; ******************************************************
	; BIOS PARAMETER BLOCK
	; ******************************************************

	jmp near boot_main

	OEMLabel		db "ARJOBOOT"	; Disk label
	BytesPerSector		dw 512		; Bytes per sector
	SectorsPerCluster	db 1		; Sectors per cluster
	ReservedSector		dw 1		; Reserved sectors for boot record
	NumberOfFats		db 2		; Number of copies of the FAT
	RootEntries		dw 224		; Number of entries in root dir
						; (224 * 32 = 7168 = 14 sectors to read)
	LogicalSectors		dw 2880		; Number of logical sectors
	MediumByte		db 0F0h		; Medium descriptor byte
	SectorsPerFat		dw 9		; Sectors per FAT
	SectorsPerTrack		dw 18		; Sectors per track (36/cylinder)
	HeadCount		dw 2		; Number of sides/heads
	HiddenSectors		dd 0		; Number of hidden sectors
	LargeSectors		dd 0		; Number of LBA sectors
	DriveNo			dw 0		; Drive No: 0
	Signature		db 41		; Drive signature: 41 for floppy
	VolumeID		dd 00000000h	; Volume ID: any number
	VolumeLabel		db "ARJOBOS    "; Volume Label: any 11 chars
	FileSystem		db "FAT12   "	; File system type: don't change!

	; ******************************************************
	; MACRO BLOCK
	; ******************************************************

%macro	printString 1
	push ax
	push si

	mov ax, %1
	mov si, ax
%%.repeat:
	lodsb
	mov ah, 0xE
	int 0x10
	cmp al, 0
	jne %%.repeat

	pop si
	pop ax
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
boot_main:	
	; Setup the Stack
	; The Stack is 4k in size and starts at location 0x7BFF or 6C0:FFF
	; Each of the segment starts at 16 bit boundary an 4k space must be
	; allocated from the start of that segment. Therefore
	; 	segment * 0x10 + 0xFFF = 0x7BFF => segment = 0x6C0
	;
	cli		; disable interrupts
	mov ax, 0x6C0
	mov ss, ax
	mov sp, 0xFFF
	sti		; enable interrupts

	; reset the floppy drive
	mov ah, 0
	mov dl, 0
	int 0x13
	
	jc failed

	; switch to 0x13 mode
	mov ah, 0
	mov al, 0x13	; 256 color palette 320*200 vga
	int 0x10

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
	printString filenotfoundstr
	jmp exit

.filefound:
	pop cx
	; read the file start sector
	mov ax, word [buffer + bx + 0x1A]
	mov [filesector], ax

	; read file size at 32 bit number
	mov ax, word [buffer + bx + 0x1C]	; first 16 bits of file size
	mov [fileremsize], ax

	mov ax, word [buffer + bx + 0x1E]	; second 16 bits of file size
	mov [fileremsize+2], ax
readfiledata:
	; set the requested size of the file = file size if the former is
	; greater.
	; TODO: do 32 bit compare
	;mov ax, [filesize]
	;cmp [filereqsize], ax		
	;jbe  .lesser			; requested size =< filesize

	; requested size > file size
	;mov [filereqsize], ax		; requested size = filesize 
;.lesser:
	; keep the requested size as backup for later
	; needed for calculation of total bytes read
	;mov ax, [filereqsize]
	;mov [fileremsize], ax		; reading will continue while 
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
	push es				; preserve the ES value before change
	mov dx, cx
	;mov bx, [filereqsize]		; read bytes = required - remaining
	;sub bx, [fileremsize]		; used to increment the out buffer
	cld				; set direcection flag = 0 (increment)
	mov si, buffer
	mov ax, osegment		; set up destination address
	mov es, ax
	mov di, [osegoffset]
	rep movsb
	pop es				; restore the ES register
	; update remaining size variable.
	sub word [fileremsize], dx	; remaining = remaining - bytes read
	add word [osegoffset], dx	; osegoffset now points to the next
					;location to write to.
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

	; reading is complete
	
	; halt
	jmp exit

	; jump to kernel code
	;mov ax, 0x800
	;mov ds,ax
	;jmp 0x800:0

failed:
	; failed
	printString failedstr
	jmp exit

exit:	
	jmp $

%include "../common/readsector.s"

failedstr:  	db	'DRIVE ERROR',0
filenotfoundstr:db      'KERNEL IS MISSING.',0

bootfilename:	db	'OSSPLASHBIN'
;bootfilename:	db	'KERNEL     '

RootDirSectors:	dw 	14

filesector:	resw 	1
fileremsize	resw 	1

osegoffset	resw	0x0
osegment	equ 	0xA000
;osegment	equ 	0x800

    ; ******************************************************
    ; END OF BOOT LOADER
    ; ******************************************************
    times 510 - ($-$$) db 0
		dw 	0xAA55

    ; ******************************************************
    ; FILE IO BUFFER
    ; ******************************************************
buffer:
