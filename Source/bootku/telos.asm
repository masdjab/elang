org 0100h
jmp begin

include 'libs\load_all.asm'
include 'libs\logo.asm'

OSStart           db 'TELOS', 13, 10
                  db 'Sistem Operasi Cap Telo', 13, 10
                  db 'Edisi Kripik Tempe', 13, 10, 0
OSInfo			      db 'Sistem operasi ini dapat menampilkan isi file teks ke layar',13,10
                  db 'dan menjalankan program .COM atau .EXE',13,10,13,10
                  db '+ Ketikkan DIR untuk melihat file di disket',13,10
                  db '+ Ketikkan CLS untuk menghapus layar',13,10
                  db '+ Ketikkan nama file teks untuk melihat isinya',13,10
                  db '+ Ketikkan nama file .COM atau .EXE untuk dijalankan',13,10,0
OSHelp			      db 'Ketikkan perintah atau nama file .TXT, .EXE atau .COM.',13,10
exithlp 		      db 'Ketik "EXIT" untuk keluar.',13,10,13,10,0
cmdprompt		      db 'A:> ',0
cmdexit 		      db 'EXIT',0
cmdlist 		      db 'DIR',0
cmdcls			      db 'CLS',0
cmddel			      db 'DEL',0
cmdenv			      db 'ENV',0
cmdkbsave		      db 'KBSAVE',0
cmdhlp			      db 'HELP',0
cmdqst			      db '?',0
extcom			      db '.COM'
extexe			      db '.EXE'
exttxt			      db '.TXT'
msglist 		      db 'File di drive A:',13,10,0
msgend			      db 'Sesi selesai. Matikan CPU!',13,10,0
msginvalidfn		  db 'Nama file tidak valid.',13,10,0
msgdeleted		    db ' deleted',13,10,0
msgalreadyexist 	db ' sudah ada. Overwrite(Y/N)? ',0
msgdiskfull		    db 'Disket sudah penuh!',13,10,0
msgbadcmd		      db 'Perintah atau nama file tidak valid.',13,10,0
msgnotexecutable  db ' bukan file teks atau file executable.',13,10,13,10,0
msgsimulated		  db 'Eksekusi program mode DOS atau Windows.',13,10,13,10,0
msgnofile		      db 'Tidak ada file di drive A:.',13,10,0
msgdiskerror		  db 'Error pada saat membaca disket. Error #',0
txtnotfound		    db ' tidak ketemu',13,10,0
txtreginfo		    db 'Informasi register:',13,10,0
txtreges		      db 'ES=',0
txtregcs		      db 'CS=',0
txtregds		      db 'DS=',0
txtregss		      db 'SS=',0
txtregax		      db 'AX=',0
txtregcx		      db 'CX=',0
txtregdx		      db 'DX=',0
txtregbx		      db 'BX=',0
txtregsp		      db 'SP=',0
txtregbp		      db 'BP=',0
txtregsi		      db 'SI=',0
txtregdi		      db 'DI=',0
txtzr			        db 'ZR',0
txtnz			        db 'NZ',0
txtcy			        db 'CY',0
txtnc			        db 'NC',0
txtdummy		      db 'Dummy area: ',0
txtfreeheap		    db 'Free heap : ',0
txtbytes		      db ' bytes.',0
txtrunfrom		    db 'OS dijalankan',0
txtunderdos		    db ' di bawah lingkungan DOS/Windows (mode simulasi).',0
txtunderbld		    db ' langsung dari Boot Loader.',0
txtfiles		      db ' file.',13,10,13,10,0
txtspaces		      db '  ',0
txtbyteswritten 	db ' byte tersimpan.',0
txtlength		      dw 0
cmdlength		      dw 0
cmdptr			      dw 0


_setrestorepoint:		;Catat lokasi CS:IP sekarang
   push bp			;agar dapat kembali ke prompt
   mov bp, sp			;setelah mengeksekusi program
   push ax			;.EXE atau .COM
   mov ax, [bp+02]
   mov [_sysoffset], ax
   pop ax
   pop bp
   ret


begin:
   mov ax, cs			;Set semua register segmen,
   mov ds, ax			;samakan dengan register CS
   mov ss, ax
   mov sp, 0FFFEh
   call _sysinit
   call _cls
   push es
   push ds
   getcursor
   print OSStart		;Tampilkan logo Sistem Operasi
   shworicreator		;shworicreator or shwmodcreator
   print OSInfo
   print exithlp
   call _setrestorepoint
   pop ds			;Ambil kembali nilai DS dan ES
   pop es			;setelah mengeksekusi program
   getcursor
   forcelinefeed

CMDREADY:
   strfill _syscmdbuffer, 20h, 0
   print cmdprompt		;Tampilkan command prompt
   input _syscmdbuffer		;dan baca perintah dari user
   forcelinefeed
   ltrim _syscmdbuffer, _syscmdbuffer, cx
   mov [txtlength], cx
   mov ax, _syscmdbuffer
   mov [cmdptr], ax
   mov di, _sysedtbuffer
   getword cmdptr, di
   test cx, cx
   jz _emptycommand
   cmp al, 2Eh
   jnz _extnotspcfd
;first word is a file name:
   mov dx, cx
   add di, cx
   stosb		     ;AL = '.'
   inc [cmdptr]
   inc dx
   getword cmdptr, di
   add cx, dx
_extnotspcfd:
   ucase _sysedtbuffer, _sysedtbuffer, cx
   mov al, 0
   mov di, _sysedtbuffer
   add di, cx
   mov [di], al
_evalusertext:
   cmpwdstring _sysedtbuffer, cmdexit
   jz exit
   cmpwdstring _sysedtbuffer, cmdlist
   jz CMDDIR
   cmpwdstring _sysedtbuffer, cmdcls
   jz _CLEARSCREEN
   cmpwdstring _sysedtbuffer, cmdhlp
   jz _showhelp
   cmpwdstring _sysedtbuffer, cmdqst
   jz _showhelp
   cmpwdstring _sysedtbuffer, cmdkbsave
   jz _KBSAVE
   cmpwdstring _sysedtbuffer, cmddel
   jz _DELETEFILE
   cmpwdstring _sysedtbuffer, cmdenv
   jz _SYSENVIRONMENT
   jmp _EXECUTEFILE

_emptycommand:
   forcelinefeed		;Kembali ke prompt jika teks
   jmp CMDREADY 		;perintahnya string kosong


CMDDIR:
   getword cmdptr, _sysedtbuffer
   mov si, _sysedtbuffer
   xor ax, ax
   cmp cx, 3
   jnc _schattributeset
   mov ax, 3030h
_loadatrdigits:
   mov ah, [si]
   inc si
   xchg ah, al
   loop _loadatrdigits
   bval
_schattributeset:
   print msglist
   mov [_crtschatr], ax
   resetsearch
   xor cx, cx
_dirschnextfile:
   mov ax, [_crtschatr]
   findfile ax
   jnz _endofdir
   jc _dirschnextfile
   mov si, [_crtschofs]
   print txtspaces
   test byte [si+0Bh], 10h
   jz _notdiropen
   putchar '\'
   jmp _printfilename
_notdiropen:
   putchar ' '
_printfilename:
   push si
   mov al, 0
   mov ah, [si+08]
   mov [si+08], al
   print si
   putchar ' '
   mov [si+08], ah
   add si, 8
   mov ah, [si+3]
   mov [si+3], al
   print si
   mov [si+3], ah
   print txtspaces
   pop si
   mov al, [si+0Bh]
   xor ah, ah
   hex bytestrvalue, ax
   print bytestrvalue
_printfilesize:
   print txtspaces
   mov ax, [si+1Ch]
   whex wordstrvalue, ax
   print wordstrvalue
_countfiles:
   inc cx
   forcelinefeed
   jmp _dirschnextfile
_endofdir:
   test cx, cx
   jz _nomorefilefound
   decstr _sysedtbuffer, cx
   print _sysedtbuffer
   print txtfiles
   jmp CMDREADY
_nomorefilefound:
   print msgnofile
   forcelinefeed
   jmp CMDREADY


_CLEARSCREEN:
   clearscreen
   jmp CMDREADY


_KBSAVE:
   strfill _sysedtbuffer, 12, ' '
   mov di, _sysedtbuffer
   getword cmdptr, di
   push cx
   cmp al, 2Eh
   jnz _kbsavefnloaded
   inc [cmdptr]
   add di, 8
   getword cmdptr, di
   pop cx
_kbsavefnloaded:
   ucase _sysedtbuffer, _sysedtbuffer, 11
   strinsertchr _sysedtbuffer, 11, 0
   test cx, cx
   jz _invalidfilename
_kbsavenotzstr:
   resetsearch
_kbsaveschfile:
   findfile 0
   jnz _kbsavefnfree
   jc _kbsaveschfile
   mov ax, [_crtschofs]
   cmpstring ax, _sysedtbuffer, 11
   jnz _kbsaveschfile
   fncompress [_crtschofs], _sysfilename
   print _sysfilename
   print msgalreadyexist
_kbsaveqst:
   readkey
   cmp al, 'Y'
   jz _kbsaveovw
   cmp al, 'y'
   jz _kbsaveovw
   cmp al, 'N'
   jz _kbsaveesc
   cmp al, 'n'
   jz _kbsaveesc
   jmp _kbsaveqst
_kbsaveesc:
   putchar ax
   forcelinefeed
   forcelinefeed
   jmp CMDREADY
_kbsaveovw:
   putchar ax
   forcelinefeed
_delexistfile:
   mov si, [_crtschofs]
   mov al, 0E5h
   mov [si], al
   mov dx, [si+1Ah]
   mov ax, [_crtdirsct]
   writesector [_mainsctbuffer], 0, ax, 1
   setcluster dx, 0
   jmp _kbsaveschfile
_kbsavefnfree:
   mov di, [_dskwrbuffer]
   xor dx, dx
_kbrdnxtline:
   input di
   forcelinefeed
   add dx, cx
   cmp al, 27
   jz _kbreadfinished
   add di, cx
   mov ax, 0A0Dh
   stosw
   add dx, 2
   jmp _kbrdnxtline
_kbreadfinished:
   test dx, dx
   jz _zerobfrlen
   push dx
   mov di, [_dskwrbuffer]
   add di, dx
   mov cx, 200h
   sub cx, dx
   strfill di, cx, 0
   newfile _sysedtbuffer, [_dskwrbuffer], dx
   pop dx
   jnc _zerobfrlen
   print msgdiskfull
   forcelinefeed
   jmp CMDREADY
_zerobfrlen:
   print _sysedtbuffer
   putchar ','
   putchar ' '
   decstr wordstrvalue, dx
   print wordstrvalue
   print txtbyteswritten
   forcelinefeed
   forcelinefeed
   jmp CMDREADY


_DELETEFILE:
   strfill _sysedtbuffer, 11, 20h
   mov di, _sysedtbuffer
   getword cmdptr, di
   mov dx, cx
   cmp al, 2Eh
   jnz _delfnnoext
   inc [cmdptr]
   add di, 8
   getword cmdptr, di
_delfnnoext:
   ucase _sysedtbuffer, _sysedtbuffer, 11
   strinsertchr _sysedtbuffer, 11, 0
   test dx, dx
   jz _invalidfilename
_deletingfile:
   delete _sysedtbuffer
   pushf
   print _sysedtbuffer
   popf
   jz _deleteok
   print txtnotfound
   forcelinefeed
   jmp CMDREADY
_deleteok:
   print msgdeleted
   forcelinefeed
   jmp CMDREADY


_SYSENVIRONMENT:
   print txtreginfo
_printregsvalue:
   print txtspaces
   print txtreges
      whex wordstrvalue, es
      print wordstrvalue
   print txtspaces
   print txtregcs
      whex wordstrvalue, cs
      print wordstrvalue
   print txtspaces
   print txtregds
      whex wordstrvalue, ds
      print wordstrvalue
   print txtspaces
   print txtregss
      whex wordstrvalue, ss
      print wordstrvalue
   forcelinefeed

   print txtspaces
   print txtregax
      whex wordstrvalue, ax
      print wordstrvalue
   print txtspaces
   print txtregcx
      whex wordstrvalue, cx
      print wordstrvalue
   print txtspaces
   print txtregdx
      whex wordstrvalue, dx
      print wordstrvalue
      print txtspaces
   print txtregbx
      whex wordstrvalue, bx
      print wordstrvalue
   forcelinefeed

   print txtspaces
   print txtregsp
      whex wordstrvalue, sp
      print wordstrvalue
   print txtspaces
   print txtregbp
      whex wordstrvalue, bp
      print wordstrvalue
   print txtspaces
   print txtregsi
      whex wordstrvalue, si
      print wordstrvalue
   print txtspaces
   print txtregdi
      whex wordstrvalue, di
      print wordstrvalue
   forcelinefeed
   forcelinefeed
_printflaginfo:
   print txtspaces
   mov si, txtzr
   jz _printzf
   mov si, txtnz
_printzf:
   print si
   putchar ' '
   mov si, txtcy
   jc _printcf
   mov si, txtnc
_printcf:
   print si
   forcelinefeed
   forcelinefeed
_printdummy:
   print txtspaces
   print txtdummy
      whex wordstrvalue, _dummyarea
      print wordstrvalue
      forcelinefeed
   print txtspaces
   print txtfreeheap
      whex wordstrvalue, [_freeheap]
      print wordstrvalue
      putchar ' '
      whex wordstrvalue, [_heapsize]
      print wordstrvalue
      print txtbytes
   forcelinefeed
   forcelinefeed
_printsysenv:
   print txtrunfrom
   mov ax, 5048h
   cmp [_runmode], ax
   mov si, txtunderdos
   jnz _envknown
   mov si, txtunderbld
_envknown:
   print si
   forcelinefeed
   forcelinefeed
   jmp CMDREADY


_EXECUTEFILE:
   resetsearch
_schexefile:
   findfile 0
   jnz _INVALIDCMD
   jc _schexefile
   mov si, _sysedtbuffer
   fncompress [_crtschofs], _sysfilename
   mov di, _sysfilename
   cmpwdstring si, di
   jnz _schexefile
   getwordsize si
   add si, cx
   add di, cx
   mov al, '.'
   cmp [si], al
   jnz _crtfilematch
   mov dx, si
   inc dx
   getwordsize dx
   add dx, cx
   inc cx
   cmpstring si, di, cx
   jnz _schexefile
_crtfilematch:
   cmpstring di, exttxt, 3
   jz _TXTHANDLE
   cmpstring di, extcom, 3
   jz _EXEHANDLE
   cmpstring di, extexe, 3
   jz _EXEHANDLE
   fncompress [_crtschofs], _sysfilename
   print _sysfilename
   print msgnotexecutable
   jmp CMDREADY


_TXTHANDLE:
   mov si, [_crtschofs]
   loadfile si, es, [_dskrdbuffer], 0
   ;loadfile si, es, [_freeheap], 0
   mov si, [_dskrdbuffer]
   add si, cx
   mov al, 0
   mov [si], al
   print [_dskrdbuffer]
   forcelinefeed
   forcelinefeed
   jmp CMDREADY

_EXEHANDLE:
   mov ax, 5048H
   cmp [_runmode], ax
   mov ax, _execsegment
   jz _execready
_runDOS:
   print msgsimulated
   mov ax, es
   add ax, 800h
_execready:
   push es
   push ds
   mov si, [_crtschofs]
   loadfile si, ax, _execoffset, 0
   push [_syssegment]
   push [_sysoffset]
   mov cx, [txtlength]
   add cx, _syscmdbuffer
   mov si, [cmdptr]
   cmp si, cx
   jnc _exehavenoprm
   inc si
_exehavenoprm:
   sub cx, si
   mov es, ax
   push ax
   mov di, 82h
   strcopy si, di, cx
   mov ax, cx
   mov ah, 20h
   mov [es:di-2], ax
   add di, cx
   mov al, 0
   mov [es:di], al
   pop ax
   mov ds, ax
   push es
   push _execoffset
   mov dx, 5048H
   retf

_invalidfilename:
   print msginvalidfn
   forcelinefeed
   jmp CMDREADY

_INVALIDCMD:
   print msgbadcmd
_showhelp:
   print OSHelp
   jmp CMDREADY

;_showhelp:
;   forcelinefeed
;   jmp CMDREADY

exit:
   mov ax, 5048h
   cmp [_runmode], ax
   jz exitboot
   int 20h
exitboot:
   print msgend
   hlt


_dummyarea:

