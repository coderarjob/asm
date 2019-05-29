/*
* A 'hello world' type DOS program
* To compile to a 16bit assembly, we can use the .code16gcc directive or
* compile with the -m16 option in gcc. Note that the -m16 option is only
* available in gcc 4.9 and above
*/

__asm__(
	".code16gcc;"
	"call dosmain;"
	"mov $0x4C, %AH;"
	"int $0x21;"
);

void print(char *str)
{
	__asm__(
		"mov $0x09, %%ah;"
		"int $0x21;"
		: // no output
		: "d"(str)
		: "ah"
	);
}

void dosmain()
{
	// DOS system call expects strings to be terminated by $.
	print("Hello world");
}

