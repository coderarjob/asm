
%ifndef __VFS_INC_
	%define __VFS_INC_

	; Flags that control few aspects of the VFS

	; MAX values
	FILESYSTEM_NAME_MAX_LENGTH: equ 10
	MAX_REGISTERED_FILESYSTEM: equ 10

	MAX_DRIVE_NAME_LENGHT: equ 10
	MAX_MOUNT_POINT_COUNT: equ 10

	; file_t typedef
	DEVICE: EQU 0
	FILESYSTEM: EQU 1

	; node_t typedef
	NORMAL: EQU 0
	DIRECTORY: EQU 1
	PIPE: EQU 2

	; All the pointers (memory locations) need to be far pointers in the
	; 'mount_point' and 'filesystem' structures, as these structures either
	; supply data from or to outside the VFS module.
	struc mount_point
		.filesystem resd 1	; struct filesystem *fs (far pointer)
		.source_file resd 1  ; struct file *source_f
		.mount_name resb MAX_DRIVE_NAME_LENGHT
	endstruc

	struc filesystem
		.fsname resb FILESYSTEM_NAME_MAX_LENGTH
		.diro resd 1		; Far pointer to dir_operations
		.fo   resd 1		; Far pointer to file_operations
	endstruc

	; Helper macro to create proocedures
	%macro PROC 1
		%1.offset resw 1
		%1.segmnet resw 1
		%1 EQU %1.offset
	%endmacro

	struc file_operations
		PROC .open  ; struct file *open(struct file*, char *filename, 
				    ; int flags);
		PROC .read  ; int (*read)(struct file*, char *buffer, int size);
		PROC .write ; int (*read)(struct file*, char *buffer, int size);
		PROC .close ; int (*close)(struct file*);
		PROC .get_attr ; struct file_attributes (*get_attr)(struct file*);
		PROC .set_attr ; int (*set_attr)(struct file*,struct file_attributes*);
	endstruc

	struc dir_operations
		PROC .create 	; int (*create)(...);
		PROC .delete	; int (*create)(...);
		PROC .open 		; struct file *open(struct file *mounted_f, 
				   		; char *foldername, int flags);
		PROC .close		; int (*close)(struct file*);
		PROC .get_attr	; struct folder_attributes (*get_attr)(...);
		PROC .set_attr	; int (*get_attr)(struct folder_attributes*,...);
	endstruc

	; struct file
	struc file
		.file_type resb 1
		.node_type resb 1
		.filename resb 11

		; union{ device_t devicel struct file *file} base;
		.device resw 1		
		.file_high resw 1	; stores the high byte of 32 bit file pointer
		.file equ .device

		;union{struct file_operations *fo, struct dir_operations *diro} ops;
		.file_op resd 1
		.dir_op equ .file_op
	endstruc

%endif
