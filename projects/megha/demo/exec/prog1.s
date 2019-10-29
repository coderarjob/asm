
mov dx,helloworld
call 0x193:0x102
retf

helloworld: db 'Hello world from planet Mars.$'
