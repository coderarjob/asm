bootloader.flp: bootloader.bin
	cp bootloader.bin bootloader.flp

bootloader.bin: bootloader.s
	nasm -g bootloader.s -o bootloader.bin

