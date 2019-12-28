;81h parameter length
;82h command parameter


;FLOPPY NOTES:
;- Sections:
;  - Boot: Sector 01
;  - FAT1: Sector 02 - 0A (9 sectors)
;  - FAT2: Sector 0B - 12 (8 sectors)
;  - Root: Sector 13 - 20 (14 sectors)
;  - Data: Sector 21 (Cluster 2; Cluster 0 = Sector 1F)
;- Sectors/Track = 12h
;- Total sectors = 0B40h?
;- FAT
;  - If the disk is empty, FAT 1 and FAT 2 contains F0 FF FF
;  - 000 = Free space
;  - FFF = End of File
;  - FF7 = Bad Cluster
;  - Other = Next Cluster
;- DOS DTA:
;  Offset Description
;  00h     File Name
;  08h     File Extension
;  0Bh     File Attribute
;  0Ch     Reserved for DOS
;  16h     Time
;  18h     Date
;  1Ah     First Cluster Number
;  1Ch     File Size
;
;- WIN File Name
;  00h     "A" if exist, E5h if deleted
;
;  DOS File Name
;  00h     E5 if deleted
;
;  File Attribute:
;  00h = Normal
;  01h = Read Only
;  02h = Hidden
;  04h = System
;  08h = Volume Label
;  10h = Subdirectory
;  20h = Archive
;
;  LABEL = 20h (Archive) + 08h (Volume Label)
;  WINFN = 0Fh (Volume, System, Hidden, Read Only)

;  0000  F0 FF FF.FF 0F 00 FF FF-FF FF 0F 00 FF FF FF 00   ................
;  0010  00 00 FF FF FF 0F 00 01-11 20 01 13 F0 FF 15 F0   ......... ......
;  0020  FF FF 8F 01 19 A0 01 FF-FF FF FF EF 01 FF FF FF   ................
;  0030  21 F0 FF 00 00 00 00 00-00 00 00 00 00 00 00 00   !...............
;  0040  00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00   ................
;  0050  00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00   ................


;FLOPPY FORMAT
;Ofs Length  Field                      Sample Value
;00  word    jmp command                    EB3C
;02  byte    nop command                      90
;03 08 bytes system version             MSWIN4.1
;0B  word    bytes/sector                   0200
;0D  byte    sectors/cluster                  01
;0E  word    reserved sectors               0001
;10  byte    number of FATs                   02
;11  word    max. root entries              00E0
;13  word    small total sectors            0B40
;15  byte    media descriptor byte            F0
;16  word    sectors/FAT                    0009
;18  word    sectors/track                  0012
;1A  word    disk heads                     0002
;1C  word    hidden sectors                 0000
;1E  word    reserved                       0000

;Following fields start from DOS 4+
;20  dword   huge total sectors         00000B40    ;if offset 13 contain zero
;24  byte    physical drive number            00
;25  byte    reserved                         00
;26  byte    signature byte                   29
;27  dword   volume serial number       350518E3
;2B 11 bytes volume label                BOOT95B
;36 08 bytes file system                 FAT12
;3E          boot code

;Alternative fields:
;  19 24 Sectors per FAT       000004FF
;  1D 28 Extended flags            0000
;  21 2C Root cluster number   00000002
;  25 30 FSI Sector Number         0001
;  38 43 Volume Serial Number  39280A08
;  3C 47 Volume Label (11 bytes)NO NAME
;  Observed:
;     52 File System (8 bytes)    FAT32

