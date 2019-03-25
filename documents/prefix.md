#Operand size and address size override prefixes

Starting with 80386, we can use operandsize- and addressize- override prefixes.
These can be used in combination with the 16 bit address mode and with the 32
bit address mode. These prefixed reverse the default operand size and/or the
address size for the one instruction in the code segment. 

Operand override, 66h. Changes size of data expected by default mode of the
instruction e.g. 16-bit to 32-bit and vice versa.

Address override, 67h. Changes size of address expected by the instruction.
32-bit address could switch to 16-bit and vice versa.

##The D Flag

The D flag in the code segment descriptor (Global descriptor Table/Local
descriptor table) (if GDT/LDT are not there then we become the 16 bit address
mode after the POST is done by the BIOS)
The default operand size and address size is specified by the D/B flag in the
code descriptor table.
* D/B  --> If clear, then use 16 bit address and operand size
* D/B  --> If set, we use 32 bit address and operand size.

###Example:
The processor can interpret the (MOV mem, reg) instruction in any of four
ways: 

####In a 32-bit code segment: 
* Moves 32 bits from a 32-bit register to memory using a 32-bit effective 
address. 
* If preceded by an operand-size prefix, moves 16 bits from a 16-bit 
register to memory using a 32-bit effective address. 
* If preceded by an address-size prefix, moves 32 bits from
a 32-bit register to memory using a 16-bit effective address. 
* If preceded by both an address-size prefix and an operand-size prefix, 
moves 16 bits from a 16-bit register to memory using a 16-bit effective
address.

####In a 16-bit code segment: 
* Moves 16 bits from a 16-bit register to memory using a 16-bit effective 
address. 
* If preceded by an operand-size prefix, moves 32 bits from a 32-bit register 
to memory using a 16-bit effective address. 
* If preceded by an address-size prefix, moves 16 bits from a 16-bit register 
to memory using a 32-bit effective address. 
* If preceded by both an address-size prefix and an operand-size prefix,
moves 32 bits from a 32-bit register to memory using a 32-bit effective 
address.

