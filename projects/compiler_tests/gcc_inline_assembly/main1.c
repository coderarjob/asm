/*
* This is the basic inline assembly.
*
* GNU documentation:
* ------------------
* The asm keyword is a GNU extension. When writing code that can be compiled
* with -ansi and the various -std options, use __asm__ instead of asm.
*
* (https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html#Extended-Asm)
* (https://gcc.gnu.org/onlinedocs/gcc/Alternate-Keywords.html#Alternate-Keywords)
* 
* AT&T syntax information:
* ------------------------
* https://www.codeproject.com/articles/15971/using-inline-assembly-in-c-c
*/
#include <stdio.h>

int main(int argc, char *argv[])
{
	__asm__ (
		"movl $100, %ebx;"
		"movl %ebx,%eax;"
		"nop;"
	);
}
