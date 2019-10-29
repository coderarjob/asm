#include<stdio.h>
#include<stdint.h>

void cpuid(int code, 
			uint32_t *eax, 
			uint32_t *ebx, 
			uint32_t *ecx, 
			uint32_t *edx)
{
	asm volatile ("cpuid;"
					: "=a"(*eax), "=b"(*ebx), "=c"(*ecx), "=d"(*edx)
					: "a"(code));
}

void print_as_string( uint32_t eax, uint32_t ebx, uint32_t ecx, 
					  uint32_t edx)
{
	uint32_t regs[] = {ebx,edx,ecx,0};
	char *name = (char *)regs;
	printf("%s\n",name);
}

int main(int argc, char *argv[])
{
	uint32_t a,b,c,d;
	a = b = c = d = 0;

	cpuid(0, &a, &b, &c, &d);
	print_as_string(a,b,c,d);

	printf("a = %x, b = %x, c = %x, d = %x\n", a,b,c,d);
}
