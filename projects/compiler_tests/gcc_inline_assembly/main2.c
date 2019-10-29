/*
* Demostrates Extended asm extension of gcc
* Extended asm has the following system:
* asm("" : : :);
*
* Note:
* ----
* Points to remember is that in extended asm, we have to use %%EAX instead of
* %EAX to indicate. Single % is used to indicate a variable
*
* Note: 
* ----
* When using extended asm, using single % infront of register name would make 
* gcc complane about a missing %.
*/

int main(int argc, char *argv[])
{
	// simple assignment
	__asm__ (
		"movl $10, %%EAX;"
		"nop;"
		:
		:
		:
	);

	// variable assignment (explicit register)
	int var1;
	__asm__(
		"movl %%eax, %%ebx;"
		:"=b" (var1)
		:
		:
	);

	// variable assignment (implicit register)
	// The asm block has input var2 (saved in any register, denoted by "r")
	// the output is also var2 (again saved initially in any register, denoted
	// by "=r", = is a constrain modifier, denoting that the output operand is
	// in write-only mode.
	// var2 is copied into any of the general purpose register, and then 30 is
	// added to that register. In the end, the value of this register is moved
	// to the memory location of var2
	int var2 = 150;
	__asm__(
		"addl $30, %0;"
		:"=r" (var2)
		:"r" (var2)
	);
}
