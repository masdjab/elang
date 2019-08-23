DECLARE SUB getcmdprm ()
DECLARE SUB getword (crtword$)
DECLARE FUNCTION whex$ (numexp%)
DECLARE FUNCTION encrypt% (srctext$, baseoffset%)

prm$ = COMMAND$
'prm$ = "KECRUT " + CHR$(&H22) + "KCUERT" + CHR$(&H22)
srcstring$ = prm$

CONST sctsize% = &H1000

CLS
PRINT "STRING ENCRYPTOR"
PRINT "April 23rd, 2005"
PRINT "by mr. orche!"
PRINT

getcmdprm
IF (filename$ = "") OR (signature$ = "") OR (encstring$ = "") THEN
   PRINT "Parameter count less than needed."
   GOTO quit
END IF
strsize% = LEN(encstring$)
encsize% = strsize% \ 2
encsize% = encsize% + (strsize% - (2 * encsize%))
enctext$ = STRING$(strsize%, " ")
FOR i% = 1 TO encsize%
   oddlptr% = 2 * (i% - 1) + 1
   evnlptr% = 2 * (i% - 1) + 2
   oddrptr% = i%
   evnrptr% = encsize% + i%
   MID$(enctext$, oddlptr%, 1) = CHR$(ASC(MID$(encstring$, oddrptr%, 1)) XOR &HFF)
   IF evnlptr% <= strsize% THEN
      MID$(enctext$, evnlptr%, 1) = CHR$(ASC(MID$(encstring$, evnrptr%, 1)) XOR &HFF)
   END IF
NEXT i%
enctext$ = enctext$
PRINT encstring$ + " encrypted to " + enctext$

srcfile% = FREEFILE
OPEN filename$ FOR BINARY AS #srcfile%
filesize& = LOF(srcfile%)
IF filesize& > 0 THEN
   scts% = filesize& \ sctsize%
   rmns% = filesize& - (scts% * sctsize%)
   temp$ = STRING$(sctsize% + LEN(signature$) - 1, 0)
   temq$ = STRING$(sctsize%, 0)
   temr$ = STRING$(LEN(signature$), 0)
   FOR i% = 1 TO scts%
       baseoffset% = sctsize% * (i% - 1)
       GET #srcfile%, baseoffset% + 1, temq$
       temp$ = temq$
       IF baseoffset% + LEN(temp$) <= LOF(srcfile%) THEN
          GET #srcfile%, , temr$
          temp$ = temp$ + temr$
       END IF
       encs% = encs% + encrypt%(temp$, baseoffset%)
   NEXT i%
   temp$ = STRING$(rmns%, 0)
   baseoffset% = scts% * sctsize%
   GET #srcfile%, , temp$
   encs% = encs% + encrypt%(temp$, baseoffset%)
END IF
CLOSE #srcfile%
IF filesize& = 0 THEN
   PRINT "Source file not found."
   KILL filename$
ELSE
   IF encs% > 0 THEN
      PRINT "Encryption performed " + LTRIM$(RTRIM$(STR$(encs%))) + " times."
   ELSE
      PRINT "No signature found. No encryption performed."
   END IF
END IF


quit:

FUNCTION encrypt% (srctext$, baseoffset%)
    SHARED signature$, enctext$, srcfile%
   
    crtofs% = 1
    DO WHILE crtofs% <= LEN(srctext$)
       equal% = 1
       FOR p% = 1 TO LEN(signature$)
          IF MID$(srctext$, crtofs% + p% - 1, 1) <> MID$(signature$, p%, 1) THEN
             equal% = 0
             EXIT FOR
          END IF
       NEXT p%
       IF equal% <> 0 THEN
          abspointer% = baseoffset% + crtofs% - 1
          PRINT "  Signature " + signature$ + " found at " + whex$(abspointer%)
          PUT #srcfile%, abspointer% + 1, enctext$
          enccount% = enccount% + 1
       END IF
       crtofs% = crtofs% + 1
    LOOP
    encrypt% = enccount%
END FUNCTION

SUB getcmdprm
    SHARED prm$, filename$, signature$, encstring$
    SHARED crtptr%, prmsize%

    DO WHILE crtptr% <= prmsize%
       prmcount% = prmcount% + 1
       IF prmcount% = 1 THEN getword filename$
       IF prmcount% = 2 THEN getword signature$
       IF prmcount% = 3 THEN getword encstring$
    LOOP
END SUB

SUB getword (crtword$)
    SHARED crtptr%, prmsize%, srcstring$

    IF crtptr% = 0 THEN crtptr% = 1
    prmsize% = LEN(srcstring$)
    DO WHILE crtptr% <= prmsize%
       crtchr$ = MID$(srcstring$, crtptr%, 1)
       whspc% = 0
       IF crtchr$ = " " THEN whspc% = 1
       IF crtchr$ = CHR$(9) THEN whspc% = 1
       IF whspc% = 0 THEN EXIT DO
       crtptr% = crtptr% + 1
    LOOP
    DO WHILE crtptr% <= prmsize%
       txtend% = 0
       crtchr$ = MID$(srcstring$, crtptr%, 1)
       IF literal% = 0 THEN
          IF crtchr$ = "," THEN txtend% = 1
          IF crtchr$ = " " THEN txtend% = 1
          IF crtchr$ = CHR$(9) THEN txtend% = 1
          IF crtchr$ = CHR$(&H22) THEN literal% = 1
       ELSE
          IF crtchr$ = CHR$(&H22) THEN literal% = 0
       END IF
       crtptr% = crtptr% + 1
       IF txtend% <> 0 THEN
          EXIT DO
       ELSE
          IF crtchr$ <> CHR$(&H22) THEN temp$ = temp$ + crtchr$
       END IF
    LOOP
    crtword$ = temp$
END SUB

FUNCTION whex$ (numexp%)
    temp$ = HEX$(numexp%)
    temp$ = STRING$(4 - LEN(temp$), "0") + temp$
    whex$ = temp$
END FUNCTION

