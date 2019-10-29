/* A sample file to demo the issues with compiling for a real mode 8086
 * environment*/

asm(
	"call main\n\t"
	"jmp .\n\t"
	);

#define SET_POS(r,c) (screenpos = r*160 + c*2)

typedef unsigned char uint8;
typedef unsigned short uint16;

uint16 screenpos = 0;
uint8 attr = 0xF;
uint8 ch = 0;

void write(uint8 *s, uint16 len)
{

asm(
		"push %%es\n\t"
		"mov $0xb800, %%bx\n\t"
		"mov %%bx, %%es\n\t"
		"repeat:\n\t"
		"lodsb\n\t"
		"mov %%al, %%es:(%%di)\n\t"
		"mov %4, %%es:1(%%di)\n\t"
		"add $2, %%di\n\t"
		"loop repeat\n\t"
		"pop %%es\n\t"
		:"=D" (screenpos)
		: "S" (s), "c" (len), "D" (screenpos), "lr" (attr)
		: "bx","al"
		);
}

void main()
{
	uint8 hexchars[] = {'0','1','2','3','4','5','6','7','8','9','A','B',
						'C','D','E','F'};

	uint8 i = 0;
	ch = hexchars[i];		// Problem is occuring here. SEE Listing
	write(&ch, 1);

}
