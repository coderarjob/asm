; LOADS WHOLE FILE FROM THE FLOPPY DISK TO MEMORY.
; Input: AX - Memory segment of the destination address
;	 BX - Memory offset in the segment
;	 CX - Segment of the memory location with filename
;	 DX - Memory offset with the filename
; Output: AX - 1 file read successfully, 0 file could not be read

loadFile:
	pusha
	;push ds
	;push es
	;push gs
	;push fs

	;push ax
	;xor ax, ax
	;mov ds, ax
	;mov es, ax
	;mov fs, ax
	;mov gs, ax
	;pop ax

	; save the output memory location to local memory
	mov [osegment],ax
	mov [osegoffset],bx

	; copy filename from the location pointed by CX:DX
	; to the local segment.
	push ds
	mov ds, cx
	mov si, dx
	mov di, bootfilename
	mov cx, 11
	rep movsb
	pop ds

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
	jnz .searchRootEntry

.filenotfound:
	pop cx
	inc ax	; next sector
	loop .readsector
	jmp .failed

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
.repeat:
	; setup the counter register
	cmp [fileremsize], word 0
	je .readFileEnd

	; read 512 bytes (one sector) if the file remaining size is > 512.
	mov cx, 512

	; check to see if the remaining bytes is > or < 512 (one sector size)
	cmp [fileremsize],word 512
	ja .readDataSector

	; read all the remaining bytes as it is < 512 (one sector size)
	; file remaining size >= 512
	mov cx, [fileremsize]
.readDataSector:
	mov ax, [filesector]
	add ax, 31			; sector = sector -2 + 33
	readSector ax, buffer		; read sector to internal buffer

	; we copy as many bytes in the CX register from the internal buffer to
	; the output buffer
	push es				; preserve the ES value before change
	mov dx, cx
	cld				; set direcection flag = 0 (increment)
	mov si, buffer
	mov ax, [osegment]		; set up destination address
	mov es, ax
	mov di, [osegoffset]
	rep movsb
	pop es				; restore the ES register
	; update remaining size variable.
	sub word [fileremsize], dx	; remaining = remaining - bytes read
	add word [osegoffset], dx	; osegoffset now points to the next
					; location to write to.
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
	; file was found and read is complete.
	mov [.ret], word 1
	jmp .end
.failed:
	; file was not found
	; Memory needs to written with 0 again.
	; This is becuause, it will hold the result from the previous read.
	mov [.ret], word 0
.end:
	;pop fs
	;pop gs
	;pop es
	;pop ds
	popa
	mov ax, [.ret]
	iret

.ret dw 0