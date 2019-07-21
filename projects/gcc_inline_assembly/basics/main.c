asm(
	"call dosmain\n\t"
	"mov $0x4c, %ah\n\t"
	"int $0x21\n\t"
	);

typedef unsigned char uint8;
typedef unsigned short uint16;

void foo(uint16 *v)
{
	*v = 18;
}

uint16 add(uint16 a, uint16 b)
{
	return a+b;
}
void dosmain()
{
	uint16 v = add(2,3);
	uint16 value = 19;
	uint16 *val = &value;
	foo(&value);
}
