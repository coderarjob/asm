; Main include file for kernel, driver and application developers.
; It includes the function numbers for all interrupts in the MOS kernel.
; It also includes some version information of various files in this release of
; the MOS Operating System.

%ifndef __MOS_INC__
	%define __MOS_INC__
	
	%define 	MOS_VER 		"0.1  (110819)"
	%define 	BOOTLOADER_VER 	"0.32 (110819)"
	%define 	LOADER_VER		"0.21  (130819)"
	%define		DEBUG_DRV_VER	"0.1  (100819)"
	%define		KERNEL_VER		"0.1 (180819)"

	; Segment and fixed lengths of different parts of MOS
	MDA_SEG:	EQU 		0x800
	MDA_OFF:	EQU		0x0
	MDA_LEN:	EQU		1024

	LOADER_SEG	EQU		0x800
	LOADER_OFF:	EQU		0x100
	LOADER_LEN:	EQU		768

	MODULE0_SEG:	EQU		0x840
	MODULE0_OFF:	EQU		0x64
	
	; Routines in debug.mod (accessed via INT 0x41)
	DB_PRINTHEX			EQU 0
	DB_PRINTSTR			EQU 1
	DB_CLEARSCR			EQU 2

	; Routines in despatcher.mod
	DS_ADD_ROUTINE			EQU 0x30

%endif
