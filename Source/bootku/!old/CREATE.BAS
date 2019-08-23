DECLARE SUB createbootimage ()
DECLARE SUB copysamplefiles ()
DECLARE SUB seterrtype (forcequit%, errortext$)
DECLARE SUB binwrite (filenumber%, binstring$)
DECLARE SUB getkey (keycode$)

CONST dbgfilename$ = "BOOTLDRD.TXT"
CONST bldfilename$ = "LOADER.COM"
CONST cmdfilename$ = "OS.COM"
CONST tstfilename$ = "BOOTLDRT.TXT"
CONST dirfilename$ = "Files"
linefeed$ = CHR$(13) + CHR$(10)

CLS
LOCATE , , 1
PRINT "BIKIN BOOTABLE DISK"
PRINT

PRINT "PERHATIAN!!!"
PRINT "Untuk membuat Bootable Disk, disket harus diformat dulu."
PRINT "Lanjutkan (Y/T)? ";
DO
   getkey action$
   IF (LCASE$(action$) = "y") OR (LCASE$(action$) = "t") OR (action$ = CHR$(27)) THEN EXIT DO
LOOP
PRINT

IF LCASE$(action$) = "y" THEN
   dbgfile% = FREEFILE
   OPEN dbgfilename$ FOR BINARY AS #dbgfile%
   IF LOF(dbgfile%) > 0 THEN
      CLOSE #dbgfile%
      KILL dbgfilename$
      OPEN dbgfilename$ FOR BINARY AS #dbgfile%
   END IF
   binwrite dbgfile%, "w100 0 0 1" + linefeed$
   binwrite dbgfile%, "q" + linefeed$
   CLOSE #dbgfile%
  
   ON ERROR GOTO resumeerror
   DO
      errflg% = 0
      IF insertonce% = 1 THEN PRINT "Tidak ada disket di drive A:."
      PRINT "Masukkan disket, kemudian tekan sembarang!"
      PRINT
      getkey nothing$
      tstfile% = FREEFILE
      OPEN "A:\" + tstfilename$ FOR BINARY AS #tstfile%
         temp$ = "Ini cuman file tester."
         PUT #tstfile%, , temp$
      CLOSE #tstfile%
      IF errflg% = 0 THEN
         KILL "A:\" + tstfilename$
         EXIT DO
      END IF
      insertonce% = 1
   LOOP
  
   ON ERROR GOTO fatalerror
   seterrtype 1, "Error pada saat memformat disket."
   SHELL "fmtdsk"
   PRINT "*** DISKET SUDAH DIFORMAT."
  
   seterrtype 1, "Error pada saat menulis boot record."
   SHELL "debug " + bldfilename$ + " < " + dbgfilename$
   PRINT "*** BOOT SECTOR SUDAH DITULIS."
  
   seterrtype 1, "Error pada saat menyalin file " + UCASE$(cmdfilename$) + "."
   SHELL "copy " + cmdfilename$ + " a:"
   SHELL "attrib +h A:\" + cmdfilename$
   PRINT "*** File " + UCASE$(cmdfilename$) + " sudah disalin."
  
   seterrtype 0, "File-file contoh tidak ditemukan."
   SHELL "copy " + dirfilename$ + "\*.* a:"
   IF errflg% = 0 THEN PRINT "*** FILE-FILE CONTOH SUDAH DISALIN."
   KILL dbgfilename$
   PRINT
   PRINT "BOOT DISK SUDAH JADI!!!."
ELSE
   PRINT "Pembuatan Boot Disk dibatalkan."
END IF
GOTO quit

resumeerror:
errflg% = 1
RESUME NEXT

fatalerror:
PRINT errmsg$
errflg% = 1
IF erresc% = 0 THEN
   IF errmsg$ <> "" THEN PRINT errmsg$
   RESUME NEXT
END IF

quit:

SUB binwrite (filenumber%, binstring$)
    PUT #filenumber%, , binstring$
END SUB

SUB copysamplefiles
    

END SUB

SUB getkey (keycode$)
    DO
       keycode$ = INKEY$
    LOOP UNTIL keycode$ <> ""
END SUB

SUB seterrtype (forcequit%, errortext$)
    SHARED errflg%, erresc%, errmsg$

    errflg% = 0
    erresc% = forcequit%
    errmsg$ = errortext$
END SUB

