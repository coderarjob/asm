/*
* Use of extended asm to write to a pointer.
*/
int main(int argc, char *argv[])
{
	// Assign to a pointer
	int value = 50;
	__asm__(
		"movq $90, (%%RAX);"	// move quad word (64bits) to the memory
								//address in the RAX register.
		: // no output
		:"RAX" (&value)			// RAX = &value
	);

	// Assign to an array index using memory addressing
	int ar[] = {1,2,3};
	register double int_size asm ("rbx") = sizeof(int);
	__asm__ __volatile__(
		"movl $89, (%0, %1, 2);" // mov [rax + rbx * 1], word 89
		: // no output
		: "r" (ar), "r" (int_size)
	);
	
	return 0;
}
