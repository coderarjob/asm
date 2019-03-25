# ORG directive
-----------------
https://www.nasm.us/doc/nasmdoc7.html#section-7.1 

The function of the ORG directive is to specify the origin address which NASM 
will assume the program begins at when it is loaded into memory.

For example, the following code will generate the longword 0x00000104:

				org     0x100 
				dd      label 
	label:

Unlike the ORG directive provided by MASM-compatible
assemblers, which allows you to jump around in the object file
and overwrite code you have already generated, **NASM's ORG does
exactly what the directive says: origin. Its sole function is
to specify one _offset_ which is added to all internal address
references within the section**; it does not permit any of the
trickery that MASM's version does.

# RESB and its friends
----------------------
https://www.nasm.us/doc/nasmdoc3.html#section-3.2.2 

RESB, RESW, RESD, RESQ, REST, RESO, RESY and RESZ are designed to be used in
the BSS section of a module: they declare uninitialized storage space. Each
takes a single operand, which is the number of bytes, words, doublewords or
whatever to reserve. 

		buffer:         resb    64              ; reserve 64 bytes 
		wordvar:        resw    1               ; reserve a word 
		realarray       resq    10              ; array of ten reals 
		ymmval:         resy    1               ; one YMM register 
		zmmvals:        resz    32              ; 32 ZMM registers

# INCBIN: Including External Binary Files
-------------------------------------------
https://www.nasm.us/doc/nasmdoc3.html#section-3.2.2 

INCBIN is borrowed from the old Amiga assembler DevPac: it includes a binary
file verbatim into the output file. This can be handy for (for example)
including graphics and sound data directly into a game executable file. It can
be called in one of these three ways:

    incbin  "file.dat"             ; include the whole file 
	incbin  "file.dat",1024        ; skip the first 1024 bytes 
	incbin  "file.dat",1024,512    ; skip the first 1024, and 
								   ; actually include at most 512

# 3.2.4 EQU: Defining Constants
-------------------------------
https://www.nasm.us/doc/nasmdoc3.html#section-3.2.2 

EQU defines a symbol to a given constant value: when EQU is used, the source
line must contain a label. The action of EQU is to define the given label name
to the value of its (only) operand. This definition is absolute, and cannot
change later. So, for example,

		message         db      'hello, world' 
		msglen          equ     $-message

defines msglen to be the constant 12. msglen may not then be redefined later.
This is **not a preprocessor definition either: the value of msglen is evaluated
once, using the value of $** (see section 3.5 for an explanation of $) at the
point of definition

# TIMES: Repeating Instructions or Data
-----------------------------------------
https://www.nasm.us/doc/nasmdoc3.html#section-3.2.2 

The TIMES prefix causes the instruction to be assembled multiple times. This
is partly present as NASM's equivalent of the DUP syntax supported by
MASM-compatible assemblers, in that you can code

	zerobuf:        times 64 db 0

or similar things; but TIMES is more versatile than that. The argument to
TIMES is not just a numeric constant, but a numeric expression, so you can do
things like

	buffer: db      'hello, world' 
	times 64-$+buffer db ' '

which will store exactly enough spaces to make the total length of
buffer up to 64. Finally, TIMES can be applied to ordinary
instructions, so you can code trivial unrolled loops in it:

	 times 100 movsb

Note that there is no effective difference between ```times 100
resb 1``` and ```resb 100``, except that the latter will be assembled
about 100 times faster due to the internal structure of the
assembler.
