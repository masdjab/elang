org 100h
mov ah, 9
mov dx, message
int 21h
mov ah, 8
int 21h
int 20h

message db 'Hello world...', 13, 10, 24h
