_shwmodcreator:
   jmp _shwmodcreatorcode
_shworicreator:
  jmp _shworicreatorcode
  oricreator    db 'April 2005--by mr. orche!',13,10,13,10,0
  crtby         db 'dibuat oleh:',13,10,0
  usernm        db '   Nama: HERMAN SUMANTRI',13,10
  userid        db '   NIM : 04/182275/ET/04195',13,10,13,10
		   ;   123456789012345
		   ;   HERMAN SUMANTRI
  ecnm 	   db 'USERNAME       ',0
  nmsz 	   equ 15
		   ;   04/182275/ET/04195
  ecid 	   db 'USERID            ',0
  idsz 	   equ 18

_shwmodcreatorcode:
   print crtby
   mov al, 0
   mov di, _sysedtbuffer
   strcopy usernm, di, 9
   add di, 9
   decrypt ecnm, di, nmsz
   add di, nmsz
   mov [di], al
   print _sysedtbuffer
   forcelinefeed
   mov di, _sysedtbuffer
   strcopy userid, di, 9
   add di, 9
   decrypt ecid, di, idsz
   add di, idsz
   mov [di], al
   print _sysedtbuffer
   forcelinefeed
   forcelinefeed
   ret

_shworicreatorcode:
   print oricreator
   ret

macro shwmodcreator {call _shwmodcreator}
macro shworicreator {call _shworicreator}