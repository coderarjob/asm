	
	jmp bootloader_start

	; Following is the Bios Parameter Block
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

bootloader_start:
	; clear the segment registers
	; bios loads the first sector from the boot device to memory at location
	; 0x7C00.
	; 0x7C00 location lies at the start of the segment 0x7C00/0x10 = 0x7C0
	; This is the number that new will put into the stack and data segment
	; registers.

	; we setup the stack location
	; Stack will be 1k in size.

	; way 1: code, data, stack in the same section
	mov ax,0x7C0 
	mov ds,ax
	mov ss,ax
	mov sp,0x5FF 		; 512 + 1024 = 1536 (or 0x600)

	;call bios INT 10H/0EH to print one character at a time.
	cld					;clear Direction flag (DF), so that si is incremented.
	mov si,versonmsg
	call printString

	mov si,pressanykeymsg
	call printString
	
	;wait for a character
	mov ah,00h
	int 16h

	; go into graphics mode
	mov ax,00h
	mov al,13h		; 256 color 320 x 200 vga display
	;mov al,11h		; mono 640 x 480 vga display
	;mov al,12h		; 16 color 640 x 480 vga display
	;mov al,03h		; text mode
	int 10h
	

	; test (write directly to vga text buffer at location 0xB8000
	;mov ax,0xB800
	;mov es,ax
	;mov bx,0
	;mov [es:bx],byte 'G'
	;mov [es:bx+1],byte 0x16 
	;jmp $

	; print a string in graphics mode
	mov ah,13h			; write text in graphics mode.
	mov al,1h
	mov bx,0eh
	mov cx,msglen
	;mov cx, textlen
	mov dh,10	; 10th row
	mov dl,0	; 0th column
	mov si,ds
	mov es,si
	mov bp,bootingmsg
	;mov bp, textwithattr
	int 10h

	;jmp .restart

	; display 256 VGA color pallate patterm on the screen
	mov bx,05		; row
.init1:
	mov ax,0		; pixel color
	mov cx,0		; column

.loop:
	call drawpixel
	inc ax
	inc cx
	cmp ax,0x100
	jnz .loop

	; if row equal to 50 we exit the loop
	inc bx
	cmp bx,30
	jnz  .init1

.restart:
	; wait for a keystroke and reset
	mov ah,00h
	int 16h
	
	; reboot (warning int 19H can cause problems)
	mov ah,00h
	int 19h

	;halt
	;jmp $	; or hlt (hlt caused virtual box to give a critical error message)

; draws a pixel of particular color
; input:
;	al = pixel color
;	bx = row
;   cx = column
drawpixel:
	push es
	push bx
	push dx
	push cx

	; mem = row * 320 + column => bx = bx << 8 + bx << 6 + dx
	mov dx,bx
	shl bx,8
	shl dx,6
	add bx,dx
	add bx,cx
	
	mov cx,0xA000	; extended bios video ram
	mov es,cx
	mov [es:bx],al
	
	pop cx
	pop dx
	pop bx
	pop es
	ret

printString:
	push ax
	push bx
	mov ah,0Eh		; bios call to display character
	mov bx,0h		; 0th page, and border byte (could be anything)
.rep:
	lodsb
	cmp al,0h
	jz .end
	int 10h
	jmp .rep
.end:
	pop bx
	pop ax
	ret

textwithattr:	db  'A',0x1F,'b',0x04
textlen:		equ	2

versonmsg: 		db 	"Basic boot loader by Arjob", 10, 13, 
				db 	"Version: 0.1e",10,10,13,0

pressanykeymsg: db 	"Press any key to start booting...",0

bootingmsg:		db 	"Error: Kernal.bin is not found.",10,13
				db	"Press a key to reboot..",0
msglen: 		equ $-bootingmsg

	times 510 - ($-$$) db 0
	dw 0xAA55
