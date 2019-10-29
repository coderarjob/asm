asm (".code16gcc\n\t"
	 "call dosmain\n\t"
	 "mov $0x4c, %ah\n\t"
	 "int $0x21"
	 );

#define COLUMNS 80

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;

uint8_t row,cols;

void printat(uint8_t c, uint8_t attr, uint8_t col, uint8_t row)
{
	uint16_t loc = (row * COLUMNS + col) * 2;
	__asm__ ("pushw %%gs\n\t"
			 "pushw %%bx\n\t" 
			 "movw $0xb800, %%bx\n\t"
			 "movw %%bx, %%gs\n\t"
			 "popw %%bx\n\t"
			 "movb %b0, %%gs:(%w1)\n\t"
			 "movb %b2, %%gs:1(%w1)\n\t"
			 "popw %%gs\n\t"
			 : // no output
			 : "al" (c), "bx" (loc), "cl" (attr)
			 : //"ebx"
			 );
		
}

void printhex(uint16_t num, uint8_t attr)
{
	char hexchars[] = {'0','1','2','3','4','5','6','7','8',
					   '9','A','B','C','D','E','F'};

	for(uint8_t i = 0; i < 4; 
			i++, num <<=4)
		printat(hexchars[num>>12],attr,cols++,row);
}

void printstr(char *str, uint8_t attr)
{
	while(*str)
		printat(*str++,attr,cols++,row);

}
void dosmain()
{
	row = cols = 0;
	printstr("Hello: ",0xF);
	printhex(0x78fe,0xE);
}
