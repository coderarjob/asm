OUTPUT_FORMAT(binary)
SECTIONS
{
    . = 0x0;
    .text :
    {
        *(.text);
    }
    .data :
    {
        *(.data);
        *(.bss);
        *(.rodata);
    }
    _heap = ALIGN(4);
	/DISCARD/ : 
	{
		 *(.eh_frame)
	}
}
