gcc -nostdlib \
	-ffreestanding \
	-fno-pie \
	-fno-stack-protector \
	-m16 \
	-march=i386 \
	-O0 \
	-Wl,--nmagic,--script="$1" \
	main.c -o main.com

gcc -nostdlib \
	-ffreestanding \
	-fno-pie \
	-fno-stack-protector \
	-m16 \
	-march=i386 \
	-O0 \
	-S \
	main.c -o main.s

# Notes:
# -ffreestanding -	Indicates that stdlib is not available.
# -fno-pie		 -	PIE needs _GLOBAL_OFFSET_TABLE, which is not available 
# 					in -nostdlib mode.
# -fno-stack-protector - Stack protection needs some function calls from the
# 						 stdlib (__stack_chk_fail() etc) which are not 
# 						 available in -nostdlib mode.
