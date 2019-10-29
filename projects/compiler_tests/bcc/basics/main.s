! 1 
! 1 # 1 "main.c"
! 1 #asm
!BCC_ASM
	USE16 86
	call _main
	
	mov ah, 0x4c
	int 0x21
! 7 endasm
!BCC_ENDASM
! 8 
! 9 typedef unsigned char uint8;
!BCC_EOS
! 10 typedef unsigned int uint16;
!BCC_EOS
! 11 
! 12 uint16 screen_loc = 0;
.data
export	_screen_loc
_screen_loc:
.word	0
!BCC_EOS
! 13 uint8 color = 0xF;
export	_color
_color:
.byte	$F
!BCC_EOS
! 14 uint8 ch = 0;
export	_ch
_ch:
.byte	0
!BCC_EOS
! 15 
! 16 
! 17 
! 18 void write(c,len)
! 19 # 18 "main.c"
! 18 uint8 *c;
.text
export	_write
_write:
!BCC_EOS
! 19 # 18 "main.c"
! 18 uint16 len;
!BCC_EOS
! 19 {
! 20 #asm
!BCC_ASM
_write.len	set	4
_write.c	set	2
		push bp
		mov bp, sp
		push di
		push si
		push cx
		push es

		
		mov di, #0xb800
		mov es, di
		mov di, [_screen_loc]

		
		
		mov cx, 6[bp]

		
		
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
		
		mov [_screen_loc], di

		
		pop es
		pop cx
		pop si
		pop di
		pop bp
! 59 endasm
!BCC_ENDASM
! 60 }
ret
! 61 
! 62 void printhex(num)
! 63 # 62 "main.c"
! 62 uint16 num;
export	_printhex
_printhex:
!BCC_EOS
! 63 {
! 64 	uint8 *hexchars;
!BCC_EOS
! 65 	uint8 s[4];
!BCC_EOS
! 66 	uint8 i = 0;
push	bp
mov	bp,sp
push	di
push	si
add	sp,*-7
! Debug: eq int = const 0 to unsigned char i = [S+$D-$D] (used reg = )
xor	al,al
mov	-$B[bp],al
!BCC_EOS
! 67 
! 68 #asm
dec	sp
!BCC_EOS
!BCC_ASM
_printhex.num	set	$10
.printhex.num	set	4
_printhex.hexchars	set	6
.printhex.hexchars	set	-6
_printhex.i	set	1
.printhex.i	set	-$B
_printhex.s	set	2
.printhex.s	set	-$A
	.data
	_hexchars: .ascii "0123456789ABCDEF"
.byte 0

	.text
	mov [bp-6],#_hexchars 		; assign hexchars = _hexchars
! 75 endasm
!BCC_ENDASM
!BCC_EOS
! 76 
! 77 	for(;i < 4; i++,num <<=4)
!BCC_EOS
!BCC_EOS
! 78 		s[i] = hexchars[(num & 0xF000) >> 12];
jmp .3
.4:
! Debug: and unsigned int = const $F000 to unsigned int num = [S+$E+2] (used reg = )
mov	ax,4[bp]
and	ax,#$F000
! Debug: sr int = const $C to unsigned int = ax+0 (used reg = )
mov	al,ah
xor	ah,ah
mov	cl,*4
shr	ax,cl
! Debug: ptradd unsigned int = ax+0 to * unsigned char hexchars = [S+$E-8] (used reg = )
add	ax,-6[bp]
mov	bx,ax
! Debug: ptradd unsigned char i = [S+$E-$D] to [4] unsigned char s = S+$E-$C (used reg = bx)
mov	al,-$B[bp]
xor	ah,ah
mov	si,bp
add	si,ax
! Debug: eq unsigned char = [bx+0] to unsigned char = [si-$A] (used reg = )
mov	al,[bx]
mov	-$A[si],al
!BCC_EOS
! 79 
! 80 	write("0x",2);
.2:
! Debug: postinc unsigned char i = [S+$E-$D] (used reg = )
mov	al,-$B[bp]
inc	ax
mov	-$B[bp],al
! Debug: slab int = const 4 to unsigned int num = [S+$E+2] (used reg = )
mov	ax,4[bp]
mov	cl,*4
shl	ax,cl
mov	4[bp],ax
.3:
! Debug: lt int = const 4 to unsigned char i = [S+$E-$D] (used reg = )
mov	al,-$B[bp]
cmp	al,*4
jb 	.4
.5:
.1:
! Debug: list int = const 2 (used reg = )
mov	ax,*2
push	ax
! Debug: list * char = .6+0 (used reg = )
mov	bx,#.6
push	bx
! Debug: func () void = write+0 (used reg = )
call	_write
add	sp,*4
!BCC_EOS
! 81 	write(s,4);
! Debug: list int = const 4 (used reg = )
mov	ax,*4
push	ax
! Debug: list * unsigned char s = S+$10-$C (used reg = )
lea	bx,-$A[bp]
push	bx
! Debug: func () void = write+0 (used reg = )
call	_write
add	sp,*4
!BCC_EOS
! 82 }
add	sp,*8
pop	si
pop	di
pop	bp
ret
! 83 
! 84 void main()
! Register BX SI used in function printhex
! 85 {
export	_main
_main:
! 86 	uint8 *hexchars;
!BCC_EOS
! 87 	uint8 r = 3,
push	bp
mov	bp,sp
push	di
push	si
add	sp,*-3
! Debug: eq int = const 3 to unsigned char r = [S+9-9] (used reg = )
mov	al,*3
mov	-7[bp],al
! 88 		  c = 4;
dec	sp
! Debug: eq int = const 4 to unsigned char c = [S+$A-$A] (used reg = )
mov	al,*4
mov	-8[bp],al
!BCC_EOS
! 89 #asm
!BCC_EOS
!BCC_ASM
_main.hexchars	set	2
.main.hexchars	set	-6
_main.c	set	0
.main.c	set	-8
_main.r	set	1
.main.r	set	-7
	mov [bp-6],#_hexchars
! 91 endasm
!BCC_ENDASM
!BCC_EOS
! 92 
! 93 	
! 94 	color = 0x02;
! Debug: eq int = const 2 to unsigned char = [color+0] (used reg = )
mov	al,*2
mov	[_color],al
!BCC_EOS
! 95 	for (; *hexchars;
!BCC_EOS
!BCC_EOS
! 96 			hexchars++,
! 97 r++,c+=2){
jmp .9
.A:
! 98 	
! 99 		
! 100 		(screen_loc = (2*160)+(c*2)) ; write(hexchars,1);
! Debug: mul int = const 2 to unsigned char c = [S+$A-$A] (used reg = )
mov	al,-8[bp]
xor	ah,ah
shl	ax,*1
! Debug: add unsigned int = ax+0 to int = const $140 (used reg = )
! Debug: expression subtree swapping
! Debug: eq unsigned int = ax+$140 to unsigned int = [screen_loc+0] (used reg = )
add	ax,#$140
mov	[_screen_loc],ax
!BCC_EOS
! Debug: list int = const 1 (used reg = )
mov	ax,*1
push	ax
! Debug: list * unsigned char hexchars = [S+$C-8] (used reg = )
push	-6[bp]
! Debug: func () void = write+0 (used reg = )
call	_write
add	sp,*4
!BCC_EOS
! 101 
! 102 		
! 103 		(screen_loc = (r*160)+(2*2)) ; write(hexchars,1);
! Debug: mul int = const $A0 to unsigned char r = [S+$A-9] (used reg = )
mov	al,-7[bp]
xor	ah,ah
mov	cx,#$A0
imul	cx
! Debug: add int = const 4 to unsigned int = ax+0 (used reg = )
! Debug: eq unsigned int = ax+4 to unsigned int = [screen_loc+0] (used reg = )
add	ax,*4
mov	[_screen_loc],ax
!BCC_EOS
! Debug: list int = const 1 (used reg = )
mov	ax,*1
push	ax
! Debug: list * unsigned char hexchars = [S+$C-8] (used reg = )
push	-6[bp]
! Debug: func () void = write+0 (used reg = )
call	_write
add	sp,*4
!BCC_EOS
! 104 	}
! 105 	
! 106 	color = 0xF; r = 3; c = 3;
.8:
! Debug: postinc * unsigned char hexchars = [S+$A-8] (used reg = )
mov	bx,-6[bp]
inc	bx
mov	-6[bp],bx
! Debug: postinc unsigned char r = [S+$A-9] (used reg = )
mov	al,-7[bp]
inc	ax
mov	-7[bp],al
! Debug: addab int = const 2 to unsigned char c = [S+$A-$A] (used reg = )
mov	al,-8[bp]
xor	ah,ah
inc	ax
inc	ax
mov	-8[bp],al
.9:
mov	bx,-6[bp]
mov	al,[bx]
test	al,al
jne	.A
.B:
.7:
! Debug: eq int = const $F to unsigned char = [color+0] (used reg = )
mov	al,*$F
mov	[_color],al
!BCC_EOS
! Debug: eq int = const 3 to unsigned char r = [S+$A-9] (used reg = )
mov	al,*3
mov	-7[bp],al
!BCC_EOS
! Debug: eq int = const 3 to unsigned char c = [S+$A-$A] (used reg = )
mov	al,*3
mov	-8[bp],al
!BCC_EOS
! 107 	for(;r < 19; r++)
!BCC_EOS
!BCC_EOS
! 108 		for(c =4;c < 36; c+=2,ch++){
jmp .E
.F:
! Debug: eq int = const 4 to unsigned char c = [S+$A-$A] (used reg = )
mov	al,*4
mov	-8[bp],al
!BCC_EOS
!BCC_EOS
jmp .12
.13:
! 109 			(screen_loc = (r*160)+(c*2)) ;
! Debug: mul int = const 2 to unsigned char c = [S+$A-$A] (used reg = )
mov	al,-8[bp]
xor	ah,ah
shl	ax,*1
push	ax
! Debug: mul int = const $A0 to unsigned char r = [S+$C-9] (used reg = )
mov	al,-7[bp]
xor	ah,ah
mov	cx,#$A0
imul	cx
! Debug: add unsigned int (temp) = [S+$C-$C] to unsigned int = ax+0 (used reg = )
add	ax,-$A[bp]
inc	sp
inc	sp
! Debug: eq unsigned int = ax+0 to unsigned int = [screen_loc+0] (used reg = )
mov	[_screen_loc],ax
!BCC_EOS
! 110 			write(&ch,1);
! Debug: list int = const 1 (used reg = )
mov	ax,*1
push	ax
! Debug: list * unsigned char = ch+0 (used reg = )
mov	bx,#_ch
push	bx
! Debug: func () void = write+0 (used reg = )
call	_write
add	sp,*4
!BCC_EOS
! 111 		}
! 112 
! 113 	(screen_loc = (0*160)+(0*2)) ;
.11:
! Debug: addab int = const 2 to unsigned char c = [S+$A-$A] (used reg = )
mov	al,-8[bp]
xor	ah,ah
inc	ax
inc	ax
mov	-8[bp],al
! Debug: postinc unsigned char = [ch+0] (used reg = )
mov	al,[_ch]
inc	ax
mov	[_ch],al
.12:
! Debug: lt int = const $24 to unsigned char c = [S+$A-$A] (used reg = )
mov	al,-8[bp]
cmp	al,*$24
jb 	.13
.14:
.10:
.D:
! Debug: postinc unsigned char r = [S+$A-9] (used reg = )
mov	al,-7[bp]
inc	ax
mov	-7[bp],al
.E:
! Debug: lt int = const $13 to unsigned char r = [S+$A-9] (used reg = )
mov	al,-7[bp]
cmp	al,*$13
jb 	.F
.15:
.C:
! Debug: eq int = const 0 to unsigned int = [screen_loc+0] (used reg = )
xor	ax,ax
mov	[_screen_loc],ax
!BCC_EOS
! 114 	write("OK",2);
! Debug: list int = const 2 (used reg = )
mov	ax,*2
push	ax
! Debug: list * char = .16+0 (used reg = )
mov	bx,#.16
push	bx
! Debug: func () void = write+0 (used reg = )
call	_write
add	sp,*4
!BCC_EOS
! 115 }
add	sp,*4
pop	si
pop	di
pop	bp
ret
! 116 
! Register BX used in function main
.data
.16:
.17:
.ascii	"OK"
.byte	0
.6:
.18:
.ascii	"0x"
.byte	0
.bss

! 0 errors detected
