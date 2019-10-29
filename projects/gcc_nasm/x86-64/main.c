
void _printstring(char *string, long len);
int _strlen(char *sting);

char *string = "Arjob Mukherjee\n";
int main(int argc, char *argv[])
{
    int length = 0;
    length = _strlen(string);
    _printstring(string,length);
    return 0;
}


