! 1 
! 1 # 1 "main.c"
! 1 
! 2 
! 3 #asm
!BCC_ASM
	call _start
	l: jmp l
! 6 endasm
!BCC_ENDASM
! 7 
! 8 char ch;
!BCC_EOS
! 9 
! 10 void start()
! 11 {
export	_start
_start:
! 12 	char i = 0;
push	bp
mov	bp,sp
push	di
push	si
dec	sp
! Debug: eq int = const 0 to char i = [S+7-7] (used reg = )
xor	al,al
mov	-5[bp],al
!BCC_EOS
! 13 	char array[5];
!BCC_EOS
! 14 	array[0] = '0';
add	sp,*-5
! Debug: eq int = const $30 to char array = [S+$C-$C] (used reg = )
mov	al,*$30
mov	-$A[bp],al
!BCC_EOS
! 15 	array[1] = '1';
! Debug: eq int = const $31 to char array = [S+$C-$B] (used reg = )
mov	al,*$31
mov	-9[bp],al
!BCC_EOS
! 16 	array[2] = '2';
! Debug: eq int = const $32 to char array = [S+$C-$A] (used reg = )
mov	al,*$32
mov	-8[bp],al
!BCC_EOS
! 17 	array[3] = '3';
! Debug: eq int = const $33 to char array = [S+$C-9] (used reg = )
mov	al,*$33
mov	-7[bp],al
!BCC_EOS
! 18 	
! 19 	ch = array[i];
! Debug: ptradd char i = [S+$C-7] to [5] char array = S+$C-$C (used reg = )
mov	al,-5[bp]
xor	ah,ah
mov	bx,bp
add	bx,ax
! Debug: eq char = [bx-$A] to char = [ch+0] (used reg = )
mov	al,-$A[bx]
mov	[_ch],al
!BCC_EOS
! 20 }
add	sp,*6
pop	si
pop	di
pop	bp
ret
! 21 
! Register BX used in function start
.data
.bss
.comm	_ch,1

! 0 errors detected
