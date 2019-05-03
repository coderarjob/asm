#! /bin/sh

@echo off

# Compile the bootloader
echo "Compilling bootloader.."
pushd src/bootloader
nasm -f bin boot.s -o ../../build/boot.bin || exit
popd

# Build the floppy image
echo "Creating disk image..."
rm -f disk_images/boot.flp
mkdosfs -C disk_images/boot.flp 1440 || exit

# mount the Disk image
echo "Copy needed files to the floppy image..."
runas mount disk_images/boot.flp temp || exit

# Copy the files needed to the floppy
echo "Copy ossplash.bin..."
runas cp bitmaps/bins/ossplash_v1.bin temp/ossplash.bin || exit

# Unmount the image
echo "Copy of files done. Unmounting image..."
runas umount temp || exit

# Wrtie the bootloader
echo "Writing bootloader to floppy image..."
dd conv=notrunc if=build/boot.bin of=disk_images/boot.flp || exit

echo "Done"
