/*
* Pointers of variables allocated in stack in one method cannot be accessed
* when passed to another method. Problem is solved we make them global
* variables, i.e. Allocate them out of stack
*/
asm(
	".intel_syntax noprefix\n\t"
	"call main\n\t"
	"jmp .\n\t"
	//"movb $0x4c, %ah\n\t"
	//"int $0x21\n\t"
	);

#define SET_POS(r,c) (screenpos = r*160 + c*2)

typedef unsigned char uint8;
typedef unsigned short uint16;

uint16 screenpos = 0;
uint8 attr = 0xF;
uint8 s[4] = {'0','0','0','0'};
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

uint16 strlen(char *s)
{
	uint16 len = -1;
	asm(
		"mov $0, %%al\n\t"
		"repne scasb\n\t"
		"neg %0\n\t"
		:"=c"(len)
		:"0" (len), "D" (s)
		:"al"
	);

	len -= 2;

	return len;
}

void printhex(uint16 number,uint8 length)
{
	
	char hexchars[] = {'0','1','2','3','4','5','6','7','8','9','A','B',
						'C','D','E','F'};

	for(int i = 0; i < 4; i++, number<<=4){
		s[i] = hexchars[number>>12];
	}

	write(s,4);
}

void main()
{
	//printhex(0xEFAB,2);
	uint8 hexchars[] = {'0','1','2','3','4','5','6','7','8','9','A','B',
						'C','D','E','F'};

	uint8 i = 0;
	ch = hexchars[i];
	write(&ch, 1);

	/*uint8 top_col = 4,
		  left_row = 2,
		  i = 0;

	attr = 0x2;
	for (; i < 16; i++, top_col+=3, left_row++)
	{
		ch = hexchars[i];
		// print top header
		SET_POS(1,top_col);
		write(&ch,1);

		// print left header
		SET_POS(left_row,1);
		write(&ch,1);
	}

	uint8 r = 2,
		  c  = 4;
	attr = 0xF;ch =0;
	for (; r < 18; r++){
		for (c = 4; c < 52; c+=3, ch++)
		{
			SET_POS(r,c);
			write(&ch,1);
		}
	}*/
}
