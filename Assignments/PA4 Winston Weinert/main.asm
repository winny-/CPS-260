TITLE PA4
; Program Description: Validates PINS and checks data parity
; Author: Winston Weinert
; Creation Date: 4/14/2015

INCLUDE Irvine32.inc
INCLUDE Macros.inc       ; For Irvine macro mWriteString.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;
; Macro data ;
;;;;;;;;;;;;;;

.data
testingPinMsg       BYTE 'Testing PIN: ',0
sepMsg              BYTE ', ',0
validMsg            BYTE 'VALID',0
invalidMsg          BYTE 'INVALID',0

checkingParityMsg   BYTE 'Checking parity of address ',0
hexMsg              BYTE ' (hex)',0
bytesMsg            BYTE ' bytes (dec).',0
bytesAreMsg         BYTE 'Bytes are (bin): ',0
EvenMsg             BYTE '>> EVEN PARITY',0
OddMsg              BYTE '>> ODD PARITY',0

.code
;-----------------------------------------------------
mTestPin  MACRO pinString
;
; Test a pin and report to console output.
; Recieves: pinString -- address of the pin string.
; Returns:  Nothing
;-----------------------------------------------------
     push eax

     mWriteString   testingPinMsg
     mWriteString   pinString
     mWriteString   sepMsg

     mov  eax, OFFSET pinString
     call ValidatePin

     .IF eax == 1
     mWriteString   validMsg
     .ELSE
     mWriteString   invalidMsg
     .ENDIF
     mCrlf

     pop  eax
ENDM

;-----------------------------------------------------
mCheckParity   MACRO bytes, nbytes
;
; Recieves: bytes -- address of the bytes to check.
;           nbytes -- number of bytes to check.
; Returns:  Nothing.
;-----------------------------------------------------
     LOCAL L1

     push eax
     push ebx
     push ecx
     push edx

     ;;;;;;;;;;
     ; Header ;
     ;;;;;;;;;;

     mWriteString   checkingParityMsg
     mov  eax, OFFSET bytes
     call WriteHex
     mWriteString   hexMsg
     mWriteString   sepMsg
     mov  eax, nbytes
     call WriteDec
     mWriteString   bytesMsg
     mCrlf
     mWriteString   bytesAreMsg

     ;;;;;;;;;;;;;;;;;;;;;;;;
     ; Dump bytes in binary ;
     ;;;;;;;;;;;;;;;;;;;;;;;;

     mov  edx, OFFSET bytes
     mov  ecx, nbytes
     mov  ebx, 1
L1:
     mov  al, BYTE PTR [edx]
     call WriteBinB
     inc  edx
     mWriteSpace
     loop L1
     mCrlf

     ;;;;;;;;;;;;;;;;
     ; Check parity ;
     ;;;;;;;;;;;;;;;;

     mov  eax, OFFSET bytes
     mov  ecx, nbytes
     call CheckDataParity

     ;;;;;;;;;;;;;;;;;;;;;
     ; Report to console ;
     ;;;;;;;;;;;;;;;;;;;;;

     .IF eax == 1
     mWriteString evenMsg
     .ELSE
     mWriteString oddMsg
     .ENDIF
     mCrlf

     pop  edx
     pop  ecx
     pop  ebx
     pop  eax
ENDM

;-----------------------------------------------------
mCrlf     MACRO
;
; Write a CR and LF to console.
; Recieves: Nothing.
; Returns: Nothing.
;-----------------------------------------------------
     call Crlf
ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Procedures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;-----------------------------------------------------
main PROC
;
; Program entry point.
; Recieves: Nothing.
; Returns: Nothing.
;-----------------------------------------------------
.data
validPin  BYTE '52413',0
validPin2 BYTE '95846',0
validPin3 BYTE '64544',0
badPin    BYTE '11101',0
badPin2   BYTE '99999',0
evenP     BYTE 00000001b,00100010b,10000000b
oddP      BYTE 00000000b,00000011b,01000000b,11111111b
.code
     mTestPin  validPin
     mTestPin  validPin2
     mTestPin  validPin3
     mTestPin  badPin
     mTestPin  badPin2

     mCrlf

     mCheckParity   evenP, SIZEOF evenP

     mCrlf

     mCheckParity   oddP, SIZEOF oddP

     mCrlf

     call WaitMsg

	push 0
     call ExitProcess
main ENDP

;-----------------------------------------------------
ValidatePin PROC
;
; Validates a PIN as per the validRanges array.
; Recieves: EAX -- the address of the PIN string.
; Returns:  EAX -- 1 if PIN is valid, 0 if invalid.
;-----------------------------------------------------
.data
; The valid ranges, even bytes are the lower bounds, odd are the upper bounds.
validRanges    BYTE '59','25','48','14','36'
nDigits        = LENGTHOF validRanges / 2
.code
     push ebx
     push edx
     push esi
     pushfd

     cld
     mov  esi, eax
     xor  eax, eax            ; Clear eax for easy debugging.
     lea  ebx, [validRanges]
     mov  ecx, nDigits
L1:
     lodsb
     cmp  al, [ebx]
     jb   B1             ; Is it below lower bound = invalid.
     cmp  al, [ebx+1]
     ja   B1             ; Is it above upper bound = invalid.
     add  ebx, 2         ; Move to next valid range pair.
     loop L1

     mov  eax, 1    ; Valid PIN.
     jmp  B2
B1:
     xor  eax, eax  ; Clear eax = invalid PIN.
B2:
     popfd
     pop  esi
     pop  edx
     pop  ebx
     ret
ValidatePin ENDP

;-----------------------------------------------------
CheckDataParity PROC
;
; Check the parity of an array of data.
; Recieves: EAX -- address of the data.
;           ECX -- number of bytes to check.
; Returns:  EAX -- 1 = even parity, 0 odd parity.
;-----------------------------------------------------
     push esi
     pushfd

     cld
     mov  esi, eax
     xor  eax, eax  ; Clear eax to clear ah -- used as the "sum" of the XORs, al for easier debugging.
L1:
     lodsb
     xor  ah, al
     loop L1

     setp al        ; setp sets al to the PF value, it however cannot accept registers/memory wider than a byte.
     movzx eax, al  ; zero-extend al into eax.

     popfd
     pop  esi
     ret
CheckDataParity ENDP

END main
