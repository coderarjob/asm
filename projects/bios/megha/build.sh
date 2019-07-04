#! /bin/sh

# Directory structure
# -------------------
# 1. The source files are placed in src folder or any of its subfolders.
# 2. Compilled binaries are placed in the Build folder.
# 3. Disk images for the OS is placed in the disk_images folder.

# Compile the bootloader
echo "=== Compilling bootloader ==="
pushd src/bootloader
nasm -f bin boot.s -o ../../build/boot.bin || exit
popd

pushd src/kernel
nasm -f bin kernel.s -o ../../build/kernel || exit
popd

# Build the floppy image
echo "=== Creating disk image ==="
rm -f disk_images/boot.flp
mkdosfs -C disk_images/boot.flp 1440 || exit

# mount the Disk image
echo "=== Copy needed files to the floppy image ==="
runas mount disk_images/boot.flp temp || exit

# Copy the files needed to the floppy
echo "=== Copy ossplash.bin ==="
runas cp bitmaps/bins/megha_boot_image_v2.data temp/ossplash.bin || exit
runas cp build/kernel temp/kernel || exit

# Unmount the image
echo "=== Copy of files done. Unmounting image ==="
runas umount temp || exit

# Wrtie the bootloader
echo "=== Writing bootloader to floppy image ==="
dd conv=notrunc if=build/boot.bin of=disk_images/boot.flp || exit

echo "Done"
