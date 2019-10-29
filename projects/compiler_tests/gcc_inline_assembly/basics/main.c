asm(
	"call dosmain\n\t"
	"mov $0x4c, %ah\n\t"
	"int $0x21\n\t"
	);

typedef unsigned char uint8;
typedef unsigned short uint16;

void dosmain()
{
	uint16 ar[] = {1,2,3,4,5,6,7};
}
