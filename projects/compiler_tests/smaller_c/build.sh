#!/bin/sh

SOURCE="main.c"
COMPILE=1
BOOT=0

if [ $# -gt 0 ]
then
	if [ $1 = "megha" ]
		then
		COMPILE=0
		BOOT=1
	else
		SOURCE="$1"
	fi
fi

if [ $# -eq 2 ]
then
	if [ "$2" = "megha" ]
	then
		BOOT=1
	fi
fi


if [ $COMPILE -eq 1 ]
then
	echo "::: Compiling $SOURCE file :::"
	smlrc -seg16 -huge -Wall main.c main.s
	nasm -f bin main.s -o main.com
fi
if [ $BOOT -eq 1 ]
then
	echo ":::: Mounting Megha disk ::::"
	runas mount ~/megha/disk_images/boot.flp ~/megha/temp
	echo ":::: Copying :::: "
	runas cp ./main.com ~/megha/temp/print
	runas umount ~/megha/temp
	echo "::: Done :::"
fi
