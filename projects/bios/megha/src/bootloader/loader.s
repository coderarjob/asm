; Megha OS Loader
; Loades different programs into memory and calles the _init routine.
; Version: 0.1 (11819)

	; ******************************************************
	; MACRO BLOCK
	; ******************************************************

	%macro printString 1
		push si
		    mov si, %1
		    int 0x31
		pop si
	%endmacro

	; ******************************************************
	; MAIN BLOCK
	; ******************************************************
	
; Loader is loaded at location 0x800:0x100
	ORG 0x100

	printString msg_file_loading

	mov si, fat_files
	mov di, friendly_filenames
.load_next:
	; print the name of the file to be loadede on screen. 
	printString di

	cmp [si],byte 0
	je .load_end

	mov ax, [_init_addr + 2]
	mov bx, [_init_addr]
	mov dx, si
	int 0x30

	cmp ax, 0
	je failed_file_not_found

	; call the _init routine
	push ds
		push 0		; argument count, there are none
;		    mov [_init_addr + 2], word 0x840
		    call far [_init_addr] 
		sub sp, 2	; adjust for the push 0
	pop ds

	; print 'loading complete message'
	printString msg_file_loaded

	; calculate the next segment
	; seg = (size (ax) + OFFSET (_init_addr) >> 4) +1 + seg
	add ax, [_init_addr]
	shr ax, 4
	inc ax
	add [_init_addr + 2], ax
	
	add di, 15
	add si, 11
	jmp .load_next
.load_end:
	; clear the screen
	mov bx, 2
	int 0x41

	; Print hello world
	mov bx, 1
	mov ax, hello
	int 0x41

	; print a number in hex format
	mov bx, 0
	mov ax, 0xbabe
	int 0x41

	jmp exit

failed_file_not_found:
	printString msg_file_not_found
exit:
	jmp $

; ================ Data for loader =====================
fat_files: db 'DEBUG   DRV'
           db 'KERNEL     '
           db 'IO      DRV'
           db 0

_init_addr: dw 	 0x64
            dw   0x840
; ================ Text messages =======================
friendly_filenames: db 10,13,"debug.drv...",0
		    db 10,13,"kernel......",0
		    db 10,13,"io.drv......",0
msg_file_loading: db "Loading kernel and drivers...",0
msg_file_loaded:  db "Done",0
msg_file_not_found: db "Error! Not found",0
hello: db "This is a welcome message: 0x",0

; ================ Text messages =======================
times 768 - ($ - $$) db 0


