

#asm
	call _start
	l: jmp l
#endasm

char ch;

void start()
{
	char i = 0;
	char array[5];
	array[0] = '0';
	array[1] = '1';
	array[2] = '2';
	array[3] = '3';
	
	ch = array[i];
}
