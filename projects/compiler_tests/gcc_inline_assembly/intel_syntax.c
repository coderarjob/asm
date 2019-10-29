#include<stdio.h>
int main()
{
	int value = 9;
	int ar[3] = {1,3,4};

	__asm__(
		"mov dword ptr [%0+8],7;"
		:
		:"r" (ar)
		);

	for (int i = 0; i<3;i++)
		printf("%u\n", ar[i]);
	return value;
}
		
