; Main include file for kernel, driver and application developers.
; It includes the function numbers for all interrupts in the MOS kernel.
; It also includes some version information of various files in this release of
; the MOS Operating System.

%ifndef __MOS_INC__
	%define __MOS_INC__
	
	%define 	MOS_VER 		"0.1  (110819)"
	%define 	BOOTLOADER_VER 	"0.32 (110819)"
	%define 	LOADER_VER		"0.2  (110819)"
	%define		DEBUG_DRV_VER	"0.1  (100819)"
	%define		KERNEL_VER		"-"

	; Routines in debug.mod (accessed via INT 0x41)
	DB_PRINTHEX			EQU 0
	DB_PRINTSTR			EQU 1
	DB_CLEARSCR			EQU 2

	; Routines in despatcher.mod
	DS_ADD_ROUTINE			EQU 0xF0

%endif
