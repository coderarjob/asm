
gcc -nostdlib \
	-fno-stack-protector\
	-ffreestanding \
	-fno-pie\
	-m16 \
	-march=i386 \
	-O0 \
	-S \
	main.c -o main.s

gcc -nostdlib \
	-fno-stack-protector\
	-ffreestanding \
	-fno-pie \
	-m16 \
	-march=i386 \
	-O0 \
	-Wl,--nmagic,--script="$1.ld"\
	main.c -o main.com
	
# Notes:
# -ffreestanding -	Indicates that stdlib is not available.
# -fno-pie		 -	PIE needs _GLOBAL_OFFSET_TABLE, which is not available 
# 					in -nostdlib mode.
# -fno-stack-protector - Stack protection needs some function calls from the
# 						 stdlib (__stack_chk_fail() etc) which are not 
# 						 available in -nostdlib mode.
