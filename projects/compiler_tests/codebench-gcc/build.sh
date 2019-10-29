#!/bin/sh

SOURCE="main.c"

if [ $# -eq 2 ]
then
	SOURCE="$2"
fi

echo "::: Compiling $SOURCE file :::"
ia16-elf-gcc -Wall "$SOURCE" -o main.com -T "$1.ld"
ia16-elf-gcc "$SOURCE" -S -o main.s

if [ $1 = "megha" ]
then
	echo ":::: Mounting Megha disk ::::"
	runas mount ~/megha/disk_images/boot.flp ~/megha/temp
	echo ":::: Copying :::: "
	runas cp ./main.com ~/megha/temp/print
	runas umount ~/megha/temp
	echo "::: Done :::"
fi
