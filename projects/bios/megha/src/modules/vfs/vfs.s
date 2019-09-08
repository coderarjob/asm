; A very basic implementation of the VIRTUAL FILE SYSTEM for MOS.
; The responsibilities of the VFS is to keep track of the various mounted
; filesystems and their mount points. It also should provide routines to query
; and register new file system and mount/unmount operations.
;
; --------------------------------------------------------------------------
; Routines:
; --------------------------------------------------------------------------
;   * void register_fs(struct filesystem* newfs);
;   * void mount(struct file *source, char *fsname, char *drive);
;   * int unmount(char *drive);
;   * struct mount_point *get_mount_point(char *drive);
;
; --------------------------------------------------------------------------
; Structures:
; --------------------------------------------------------------------------
; The mount_point structure keeps track of the mount points in the system
; currently installed. This structure binds the file system (thus its
; operations) with the mounted file. Any particular mount point is identified
; by the drive name (can by at max 10 bytes long, including the 
; null terminator byte)
;
; struct mount_point
; {
; 	struct filesystem *fs;	
; 	struct file source_f;
; 	char mount_point[10];
; }
; --------------------------------------------------------------------------
; The file system structure is used internally by the VFS to keep the
; filesystem operations and its name together. The name of the file system is
; used by the mount routine to retrive the filesystem operations.
; This structure exposes the operations to the outside world via the 
; mount_point structure.  
;
; struct filesystem
; {
; 	char fsname[10];
; 	struct filesystem_operations fso;
; }
; --------------------------------------------------------------------------
; This structure is again used internally by the VFS, and holds the two
; operations implemented by any file system together.

; struct filesystem_operations
; {
; 	struct dir_operations *diro;
; 	struct file_operations *fo;
; }
; --------------------------------------------------------------------------
; The members of this structure points to the respective routines in any
; filesystem. An instance of this structure along with the dir_operations is
; what gets registered in the VFS.
; The file_operations and dir_operations is what allows to add filesystems and
; access it.
; Every routine may not be initialised by every file system. However, open and
; close always need to be implemented.
; struct file_operations
; {
; 	struct file *(*open)(struct file*, char *filename, int flags);
; 	int (*read)(struct file*, char *buffer, int size);
; 	int (*write)(struct file*, char *buffer, int size);
; 	int (*close)(struct file*);
; 	struct file_attributes (*get_attr)(struct file*);
; 	int (*set_attr)(struct file*,struct file_attributes*);
; }
;
; struct dir_operations
; {
;	int (*create)(...);
;	int (*delete)(...);
;	struct file *(*open)(struct file *mounted_f, char *foldername, int flags);
; 	int (*close)(struct file*);
;	struct folder_attributes (*get_attr)(...);
;	int (*get_attr)(struct folder_attributes*,...);
; }
;
; --------------------------------------------------------------------------
; This is the one of the main structures that define any opened file (be that
; be a DEVICE file or a DIRECTORY), and also links to the base (mounted
; file / device driver) that lies below, thus forming a linked list.
; In many ways this structure is what keeps track of the nested file systems and
; their file and directory operations together with the file and directory they
; perform on. 
; For example:
; Say we mount C:\Images file to D drive using the FAT16 filesystem. The C
; drive is the mount point for the floppy0 file using the FAT12 filesystem. The
; floppy0 file resides in the drive for the devfs (say E drive).
; So the instance of the file structure for a file in the D drive would have
; the fillowing topology.
;                           d:\selfie.png -----> D drive handled by FAT16 
;                                  |
;								   v
;							  c:\images    -----> C drive handled by FAT12
;                                  |
;							       v
;							  e:\floppy0   -----> E drive handled by devfs
;                                  |
;							       v
;								floppy0    -----> Indentified by its major and
;												  minor numbers and handled 
; 												  by the floppy driver.
;
; ------------|----------------|-------------|-----------------|-----------------------|---------------------|
; File/Device	 File system	 mount point	 base.file		    base.device		 	   file_operations
; ------------|----------------|-------------|-----------------|-----------------------|---------------------|
;   floppy0           -               -               -           DEVICE(major, minor)    floppy driver
; ------------|----------------|-------------|-----------------|-----------------------|---------------------|
; The file system DEVFS is mounted in th E drive.
; ------------|----------------|-------------|-----------------|-----------------------|---------------------|
; e:/floppy0        FAT12             C        floppy0 device              -                   FAT12
;                                              file
; ------------|----------------|-------------|-----------------|-----------------------|---------------------|
; c:/Images         FAT16             D        e:\floppy0                  -                   FAT16
; ------------|----------------|-------------|-----------------|-----------------------|---------------------|

; The structure can be read this way:
;  - File/Directory/Device with name in 'filename' can be read (other operations
;    as well) using the function pointers in ops.fo (or ops.diro if file
;    represents a drectory) members. 
;  - If this file resides in a mounted drive whose parent file is base.file.
; The base union points to either a file or a device file from which the file
; structure is derived.
; 
; If the file points to a device driver, the base.device has the device 
; identity (MAJOR and MINOR) numbers.
;
;struct file
;{
;	file_t type;
;	node_t ntype;
;	char filename[11];
;	union{
;		device_t device;
;		struct file file;
;	} base;
;	union {
;		struct file_operations fo;
;		struct dir_operations diro;
;	} ops;
;	char extra[20];
;}
; --------------------------------------------------------------------------
; Type definations:
; --------------------------------------------------------------------------
; typedef enum {DEVICE, FILESYSTEM} file_t
; typedef enum {NORMAL, DIRECTORY, PIPE} node_t
; typedef int16 device_t;
; --------------------------------------------------------------------------
; Helpful macros:
; --------------------------------------------------------------------------
; MAKDEV(major, minor) ((major) << 8) | (minor))
; MINOR(d) ((d) & 0xFF)
; MAJOR(d) (((d) >> 8) & 0xFF)

; Initial version: 2092019 (2nd September 2019)
;
; =============== [ INCLUDE FLIES ] ===================
%include "../../include/vfs.inc"
%include "../../include/mos.inc"

; ============ [ CODE BLOCK ] =========
; Every module in MOS starts at location 0x64. The below 100 bytes, from 0x0 to
; 0x63 is for the future use.
	ORG 0x100
;
; The first routine in any module is the _init routine. This can be as simple
; as a retf statement or can actually be used for something importaint.
_init:
	mov ax, foofs
	call register_fs

	mov ax, foofs2
	call register_fs
	call register_fs

	mov ah, 0x4c
	int 0x21

foofs:
	istruc filesystem 
		at filesystem.fsname, db 'foofs',0
		at filesystem.diro, dd 0xaabbccdd
		at filesystem.fo, dd 0x01020304
	iend 

foofs2:
	istruc filesystem 
		at filesystem.fsname, db 'Foofs2',0
		at filesystem.diro, dd 0xaabbccdd
		at filesystem.fo, dd 0x01020304
	iend 

; Adds a new File system into the file systems list.
; Signature: 
;		void register_fs(struct filesystem* newfs);
; Input:
;	   ES:AX - Far pointer to a 'filesystem' structure.
; Output:
;		BX - 0, if successful, 1 if failure
register_fs:
	push ax
	push cx
	push dx
	push si
	push di

	; Store AX (far pointer to filesystem strucure) to DX
	mov dx, ax

	mov bx, [fslist_count]
	cmp bx, byte MAX_REGISTERED_FILESYSTEM 
	je .toomuch

	; Swap ES and DS
	; This is done early on, so that we can use instructions like MOVSB and
	; CMPSB below. At the end of it all, we will restore the registers back.
	push ds
	push es
		push es
			push ds
			pop es
		pop ds

		; Here on DS points to the data segment of the caler, and ES to the
		; current module.
		; -----------------------------------------------------------------
		; 1. Check if same file system exists in the list of registered file
		; systems.
		; -----------------------------------------------------------------
		; SI -> Location of the File system name in the input filesystem
		; structure.
		mov bx, dx
		lea si, [bx + filesystem.fsname]		; File sytem name: DS:SI

		; Returns the pointer to the file system which matches name with the
		; string in DS:SI. The match is case in-sensitive.
		; ES MUST POINT TO THE DATA SEGMENT OF THIS MODULE.
		call _get_filesystem_from_name			
		cmp bx, 0
		jne .fs_found
		; -----------------------------------------------------------------

.copy_fs_to_local:
		; -----------------------------------------------------------------
		; 2. Copy the filesystem from DS:DX (caller location) to ES:DI (Local)
		; -----------------------------------------------------------------
		; a. Get the next location in the local filesystem array
		mov bx, [es:fslist_count]
		imul bx, filesystem_size
		lea di, [es:fslist + bx]

		; b. We make SI point to the source offset
		mov si, dx

		; c. Source = DS:SI, Destination = ES:DI
		mov cx, filesystem_size
		rep movsb
		; -----------------------------------------------------------------
.done:
		; increment fs count
		inc byte [es:fslist_count]

		; Return as success
		mov bx, 0
		jmp .end

.fs_found:
		mov bx, 2
		jmp .end
.toomuch:
		mov bx, 1
.end:
	; Restore the registers
	pop ds
	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop ax

	; A far jump is required to return to the despatcher.
	ret

; Compares source with the destination anciiz string
; Input:
;		DS:SI - Source string
;		ES:DI - Destination string
;		BX    - 1 if compare binary or 0 if compare string.
; Output:
;		BS - 0, if strings match, otherwise 1
_str_is_equal:
	push ax
	push dx
	push cx
	push si
	push di

	push bx
		; Get Source length
		call _strlen			; Get the length of string at DS:SI
		mov cx, bx

		; Get Destination length
		push ds
		push es
		push si

			; Swap ES and DS
			push es
				push ds
				pop es
			pop ds
			
			; Now that ES:DI, has become DS:SI, we can call _strlen
			mov si, di
			call _strlen	
			mov dx, bx
		pop si
		pop es
		pop ds
	pop bx

	; Compare DX (Destination string length), CX (Source string length)
	cmp dx, cx
	jb .continue

	; DX > CX, so we make CX = DX (the maximum count)
	mov cx, dx

	; Check if we need to do a case sensitive compare or a insensitive one.
.continue:
	cmp bx, 0
	je .case_insensitive_match

.case_sensitive_match:
	rep cmpsb
	cmp cx, 0
	je .match
	jne .notmatch

.case_insensitive_match:
	mov bx,2
.readsource:
	mov al, [ds:si]
	jmp .tolower
.readdestination:
	mov ah, al
	mov al, [es:di]
.tolower:
	; Check to see AL >= 'A' and AL <= 'Z'
	; If AL is in upper case then makes it lower case
	cmp al, 'A'
	jb .not_upper
	
	cmp al, 'Z'
	ja .not_upper

	; Make AL lower case 
	; if AL = A, then AL + 'a' - 'A' = 'a'
	add al, 'a' - 'A'
.not_upper:
	dec bx
	cmp bx, 1
	je .readdestination

.compare:
	cmp al, ah
	jne .notmatch

	inc si
	inc di
	loop .case_insensitive_match

.match:
	mov bx, 0
	jmp .end
.notmatch:
	mov bx, 1
.end:
	pop di
	pop si
	pop cx
	pop dx
	pop ax
	ret

; Calculates string length
; Input:
;		DS:SI - Pointer to a asciiz string
; Output:
;		BX - Length of the string
_strlen:
	push si
	push ax
		xor bx, bx
.again:
		lodsb
		cmp al, 0
		je .end

		inc bx
		jmp .again
.end:
	pop ax
	pop si
	ret

; Get near pointer to the filesystem structure which matches the supplied name.
; Note: 
; This function will most likely be called from the environment where DS points
; to the data segment of the caller module and ES points to the one of this
; module. Therefore, the file system array is available with the ES segment not
; with the DS segment.
; Input:
;		DS:SI - Contains the name of the file system.
; Output:
;		ES:BX - Location of the file system structure for the name supplied, if
; 				no match is found, BX is set to 0.
_get_filesystem_from_name:
	push dx
	push cx
	push di
	push si

	; Number of file systems already installed.
	; If there is no registered file system, we skip and return false.
	mov cx, [es:fslist_count]						
	cmp cx, 0
	je .notfound

	; Points to the next offset in the fslist array.
	xor bx, bx
.next_fs:
	lea di, [es:fslist + bx + filesystem.fsname]
	push bx
		; Match as per set in the VFS.INC file. I think it is set to 'case
		; in-sensitive' checking.
		mov bx, STRING_MATCH
		call _str_is_equal	; matches string (case insensitive) from DS:SI with
							; ES:DI
		mov dx, bx
	pop bx
	cmp dx, 0
	je .found

	add bx, filesystem_size
	loop .next_fs

.notfound:
	mov bx, 0
	jmp .end
.found:
	mov bx, di
.end:
	pop si
	pop di
	pop cx
	pop dx
	ret
		
; Creates a mount_point structure and adds it to the list of mount points.
; Signature: 
; 		void mount(struct file *source, char *fsname, char *drive);
; Input:
;		ES:AX - Pointer to the file structure
;		ES:CX - File system name. This must be one of the registered file
;				systems. String is case insensitive.
;		ES:DX - Holds a pointer to the drive name. Upto 10 characters, 
;				including the null terminator.
; Output:
;		BX - 0 if success
;			 1 if file system do not exist
;			 2 if drive is already registered.
mount:
	push bp
	mov bp, sp
	
struc mount_args
	.file_ptr resw 1
	.fsname_ptr resw 1
	.drive_name_ptr resw 1
endstruc

	sub sp, mount_args_size

	mov [bp - mount_args.file_ptr], ax
	mov [bp - mount_args.fsname_ptr], cx
	mov [bp - mount_args.drive_name_ptr], dx

	; We SWAP DS and ES early on to make it easy for us to work with the data
	; from the caller.
	push ds
	push es
	
		; SWAP the values of DS and ES
		push ds
			push es
			pop ds
		pop es

		; At this point DS points to the data segment of the caller and ES to
		; the data segment of the current module.
		
		; --------------------------------------------------------------------
		; 1. Search if a file system with the name in DS:CX exists, in
		; ES:fslist.
		; --------------------------------------------------------------------
		; _get_filesystem_from_name searches ES:fslist with the filesystem name
		; in DS:SI. Returns the pointer to the respective file system structure
		; in ES:BX.
		mov si, [bp - mount_args.fsname_ptr]
		call _get_filesystem_from_name
		cmp bx, 0
		je .filesystem_not_found
		mov dx, bx				; offset where the filesystem item is located
								; in the fslist array.
		; --------------------------------------------------------------------
		; 2. Check if drive with name in DS:DX, already exists in the 
		; ES:mountlist array.
		; --------------------------------------------------------------------
		mov si, [bp - mount_args.drive_name_ptr]
		call _get_mount_point_from_drive
		cmp bx, 0
		jne .mount_point_exists

		; --------------------------------------------------------------------
		; Copy the values in the next in the mountlist array.
		; --------------------------------------------------------------------
		mov bx, [es:mountlist_count]
		imul bx, mount_point_size

		; a. Copy filesystem pointer (ES:DX)
		lea di, [es:mountlist + bx + mount_point.filesystem]
		mov di, word dx
		mov [di+2],word es

		; b. Copy source file pointer (DS:AX)
		lea di, [es:mountlist + bx + mount_point.filesystem]
		mov di, word [bp - mount_args.file_ptr]
		mov [di+2],word ds

		; c. Copy the drive name (DS:CX)
		mov si, [bp - mount_args.drive_name_ptr]
		lea di, [es:mountlist + bx + mount_point.mount_name]
		mov cx, MAX_DRIVE_NAME_LENGHT
		rep movsb

		inc word [es:mountlist_count]
		mov bx, 0
		jmp .end
.filesystem_not_found:
		mov bx, 1
		jmp .end
.mount_point_exists:
	mov bx, 2
.end:
	pop es
	pop ds
	leave	; pop bp and set sp = bp
	ret

; Executing this routine will remove the mount point from the local mountlist
; array and decrement the mount point count.
; Signature:
; 		int unmount(char *drive);
; Input:
;		ES:AX - Points to the name of drive to unmount
; Output:
;		BX    - 0 is successful, 
;			  - 1 if drive do not exist
umount:
	push es
	push ds
	push es
		; We SWAP the DS and ES data segments
		push es
			push ds
			pop es
		pop ds

		; -----------------------------------------------------------------
		; 1. Get the mount point location 
		; -----------------------------------------------------------------
		mov si, ax
		call _get_mount_point_from_drive
	pop es
	pop ds

	cmp bx, 0
	je .not_found
	; -----------------------------------------------------------------
	; 2. If found we shift every mount point array item one item to the
	;    left to fill the gap from the removed mount point.
	; -----------------------------------------------------------------
	; Make ES = DS
	push ds
	pop es

	; DX = End address of the mountlist array
	; This is used to check, if we have passed the last item.
	lea dx, [mountlist + mount_point_size * MAX_MOUNT_POINT_COUNT]
	
	; array item to be removed. 
	mov di, bx

	; next array item to the one getting removed.
	mov si, [bx + mount_point_size]
.next:
	cmp si, dx
	jae	.last_item_to_remove

	; TODO: The below CX assignment and rep may not be required. Just one movsb
	; is all that may be is required. But REP may be faster.
	; We copy this much byte for each item.
	mov cx, mount_point_size
	rep movsb		; Copies one byte DS:SI to ES:DI and increments SI and DI

	jmp .next

.last_item_to_remove:
	sub [mountlist_count], word 1
.not_found:
		mov bx, 1
	pop es
	ret

; Returns a far pointer to a 'mount_point' structure that matches the specified
; name.
; Note: 
; This function will most likely be called from the environment where DS points
; to the data segment of the caller module and ES points to the one of this
; module. Therefore, the mount point array is available with the ES segment not
; with the DS segment.
; Signature:
;	mount_point *get_mount_point(char *drive);
; Input:
;		DS:SI - Name of the drive
; Output:
;		ES:BX  - Far Pointer to the mount_point structure in the 'mountlist'
;				 array which is part of this module.
;				 If not found, then BX is 0
_get_mount_point_from_drive:
	push dx
	push cx
	push di
	push si

	; If there is no registered mount points, we skip and return false.
	mov cx, [es:mountlist_count]
	cmp cx, 0
	je .notfound

	; Points to the next offset in the mountlist array.
	xor bx, bx
.next_mp:
	lea di, [es:mountlist + bx + mount_point.mount_name]
	push bx
		; Match as per set in the VFS.INC file. I think it is set to 'case
		; in-sensitive' checking.
		mov bx, STRING_MATCH
		call _str_is_equal	; matches string (case insensitive) from DS:SI with
							; ES:DI
		mov dx, bx
	pop bx
	cmp dx, 0
	je .found

	add bx, mount_point_size
	loop .next_mp

.notfound:
	mov bx, 0
	jmp .end
.found:
	mov bx, di
.end:
	pop si
	pop di
	pop cx
	pop dx
	ret

; Returns a far pointer to a 'mount_point' structure that matches the specified
; name. This method calls the internal _get_mount_point_from_drive routine,
; with little different segment registers.
; Signature:
;	mount_point *get_mount_point(char *drive);
; Input:
;		ES:AX - Name of the drive
; Output:
;		ES:BX  - Far Pointer to the mount_point structure in the 'mountlist'
;				 array which is part of this module.
;				 If not found, then BX is 0
get_mount_point_from_drive:
	push ds
		; SWAP DS and ES registers.
		; ES = Data segment of this module.
		push ds
			push es
			pop ds
		pop es

		; At this point DS = Data segment of the caller, ES data segment of
		; this module.
		push si
			mov si, ax

			; Searches for a mount point whose drive name is in the location in
			; DS:SI. Return in BX (an offset in the current data segment;
			; stored in the ES register)
			call _get_mount_point_from_drive
		pop si
		; Result is a far pointer in ES:BX
		; Note: 
		; As ES register is part of the result, we are not restoring it
		; back to point to the data segment of the caller (as it was when
		; entering this routine from the despatcer)
	pop ds
	retf
; =============== [ DATA SECTION ] ===================
fslist: times MAX_REGISTERED_FILESYSTEM * filesystem_size db 0
fslist_count: dw 0
mountlist: times MAX_MOUNT_POINT_COUNT * mount_point_size db 0
mountlist_count: dw 0
