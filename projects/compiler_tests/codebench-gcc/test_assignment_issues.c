/* A sample file to demo the issues with compiling for a real mode 8086
 * environment*/

#define SET_POS(r,c) (screenpos = r*160 + c*2)

typedef unsigned char uint8;
typedef unsigned short uint16;

uint16 screenpos = 0;
uint8 attr = 0xF;
uint8 ch = 0;

void main()
{
	uint8 hexchars[] = {'0','1','2','3','4','5','6','7','8','9','A','B',
						'C','D','E','F'};

	uint8 i = 0;
	ch = hexchars[i];		// Problem is occuring here. SEE Listing
}
