__asm__(
	".code16gcc;"
	"call dosmain;"
	"mov $0x4c, %ah;"
	"int $0x21;"
);

void print(char c)
{
	__asm__(
		"mov $02, %%ah;"
		"int $0x21;"
		:
		:"dl" (c)
		:"ah"
	);
}

void print2(char c)
{
	__asm__(
		"pushw %%ds\n"
		"movw $0xb800,%%bx\n"
		"movw %%bx, %%ds\n"
		"movb %0, %%bh\n"
		"movb %0, 0\n"
		"movb $0xE,1\n"
		"popw %%ds\n"
		:
		:"bl" (c)
		:"bx"
	);
}

void dosmain()
{
	print2('B');
	//uint8_t *a = (uint8_t *)(0xb8000);
	//a[0]='A';
	//*a = 'A';
	//*vga_base = 0x4109;
	//*(unsigned char *)(0xb800) = 'A';
	//print(*(unsigned char *)(0xb800));
}
