
int main()
{
	void (*main_ptr)(int, int);
	main_ptr = (void (*)(int,int))(0x100 + 0x200);
	main_ptr(4,6);
	return 0;
}
