#! /bin/sh

nasm -f bin prog1.s -o prog1.bin||exit
runas mount boot.flp tmp||exit
runas cp prog1.bin tmp||exit
runas umount tmp
