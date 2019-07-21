; MEGHA BOOT LOADER
; Version: 0.03
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

%macro printString 1
	push si
	mov si, %1
	;call printstr
	int 0x31
	pop si
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
	jc failed_drive_error 	; drive error

	; install loadFile to IVT
	xor ax, ax
	mov gs, ax
	mov [gs:0x30*4], word loadFile
	mov [gs:0x30*4+2], cs

	; install printstr to IVT
	mov [gs:0x31*4], word printstr
	mov [gs:0x31*4+2], cs

	; Read the directory and search for file

	mov ax, 0x800
	mov bx, 0x0
	mov cx, ds
	mov dx, bootfile

	int 0x30
	cmp ax, 0			; Check if read was successful
	je failed_file_not_found	; Show error message if read failed.

	; -------------------- JUMP TO LOADER
	; Read was a success, we prepare the segment registers and jump.
	mov ax, 0x800
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	jmp 0x800:0x0
	;--------------------- 
; ======================================================================
; ======================================================================

failed_drive_error:
	printString failedstr
	jmp exit
failed_file_not_found:
	printString filenotfoundstr
exit:	
	jmp $

%include "loadFile.s"
%include "printstr.s"

failedstr:  	db	'0',0
filenotfoundstr:db      '1',0
bootfile: db 'LOADER     '
;bootfile: db 'PRINT      '
; ************************************** Used by loadFile
bootfilename:	resb	11
RootDirSectors:	dw 	14
filesector:	resw 	1
fileremsize	resw 	1
osegoffset	resw	1
osegment	resw	1
;osegment	equ 	0xA000
; **************************************

    ; ******************************************************
    ; END OF BOOT LOADER
    ; ******************************************************
    times 510 - ($-$$) db 0
		dw 	0xAA55

    ; ******************************************************
    ; FILE IO BUFFER
    ; ******************************************************
buffer:
