os.flp: bootloader.bin
	echo "# Building Floppy image..."
	rm -f os.flp
	mkdosfs -C os.flp 1440
	dd conv=notrunc if=bootloader.bin of=os.flp

bootloader.bin: bootloader.s
	echo "# Assembling..."
	nasm -g bootloader.s -o bootloader.bin


