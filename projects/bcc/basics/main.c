#asm
	USE16 86
	call _main
	//l: jmp l
	mov ah, 0x4c
	int 0x21
#endasm

typedef unsigned char uint8;
typedef unsigned int uint16;

uint16 screen_loc = 0;
uint8 color = 0xF;
uint8 ch = 0;

#define SET_LOC(r,c) (screen_loc = (r*160)+(c*2))

void write(uint8 *c, uint16 len)
{
	#asm
		push bp
		mov bp, sp
		push di
		push si
		push cx
		push es

		// setup the destination location
		mov di, #0xb800
		mov es, di
		mov di, [_screen_loc]

		// setup the count register; 
		// [bp + 6] = len
		mov cx, 6[bp]

		// setup the source location
		// [bp + 4] = *c
		mov si, 4[bp]
	.rep:
		lodsb
		seg es
		mov [di], al
		mov al, [_color]
		seg es
		mov [di + 1], al
		add di, #2
		loop .rep
	.end:
		// update current screen position
		mov [_screen_loc], di

		// restore registers
		pop es
		pop cx
		pop si
		pop di
		pop bp
#endasm
}

void printhex(uint16 num)
{
	uint8 *hexchars;
	uint8 s[4];
	uint8 i = 0;

#asm
	.data
	_hexchars: .ascii "0123456789ABCDEF"
	.byte 0

	.text
	mov [bp-6],#_hexchars 		; assign hexchars = _hexchars
#endasm

	for(;i < 4; i++, num <<=4)
		s[i] = hexchars[(num & 0xF000) >> 12];

	write("0x",2);
	write(s,4);
}

void main()
{
	uint8 *hexchars;
	uint8 r = 3,
		  c = 4;
#asm
	mov [bp-6],#_hexchars
#endasm

	// Print top and left headers
	color = 0x02;
	for (; *hexchars;
			hexchars++,
			r++,c+=2){
	
		// Top headers
		SET_LOC(2,c); write(hexchars,1);

		// Left headers
		SET_LOC(r,2); write(hexchars,1);
	}
	
	color = 0xF; r = 3; c = 3;
	for(;r < 19; r++)
		for(c =4;c < 36; c+=2,ch++){
			SET_LOC(r,c);
			write(&ch,1);
		}
}
