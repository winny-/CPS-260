TITLE PA2B
; Program Description: Reverses string and arrays.
; Author: Winston Weinert
; Creation Date: 3/17/2015

INCLUDE Irvine32.inc

CRLF_ EQU <0dh, 0ah> 

.code

;-----------------------------------------------------
main PROC
;
; Program entry point
; Recieves: Nothing.
; Returns: Nothing.
;-----------------------------------------------------

.data
stringSource             BYTE 'This is the source string',0
stringTarget             BYTE LENGTHOF stringSource DUP('#')
byteArraySource          BYTE 1,2,3,4
byteArrayTarget          BYTE LENGTHOF byteArraySource DUP(0)
wordArraySource          WORD 1,2,3,4
wordArrayTarget          WORD LENGTHOF wordArraySource DUP(0)
dwordArraySource         DWORD 1,2,3,4
dwordArrayTarget         DWORD LENGTHOF dwordArraySource DUP(0)

reverseStringTitle       BYTE '###########################',CRLF_,
                              '##### Reverse String ######',CRLF_,
                              '###########################',CRLF_,
                              CRLF_,
                              0
stringSourceField        BYTE 'Source string: ',0
stringTargetField        BYTE 'Target string: ',0

reverseByteArrayTitle    BYTE '##############################',CRLF_,
                              '##### Reverse Byte Array #####',CRLF_,
                              '##############################',CRLF_,
                              0
reverseWordArrayTitle    BYTE '##############################',CRLF_,
                              '##### Reverse Word Array #####',CRLF_,
                              '##############################',CRLF_,
                              0
reverseDwordArrayTitle   BYTE '###############################',CRLF_,
                              '##### Reverse Dword Array #####',CRLF_,
                              '###############################',CRLF_,
                              0

windowRect               SMALL_RECT <0,0,79,49>   ; 80 columns, 50 rows.

.code

     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     ; Resize the console window so the output does not need scrolling ;
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     push STD_OUTPUT_HANDLE   ; We want stdout's handle.
     call GetStdHandle        ; Get the handle, placed in eax.
     
     push OFFSET windowRect        ; New coordinates of the console edges.
     push TRUE                     ; Yes, the coordinates are absolute -- not extending the original.
     push eax                      ; Handle to the console screen buffer.
     call SetConsoleWindowInfo     ; Resize the console window.

     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     ; Reverse a string demonstration ;
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     mov  edx, OFFSET reverseStringTitle
     call WriteString
     mov  edx, OFFSET stringSourceField
     call WriteString
     mov  edx, OFFSET stringSource
     call WriteString
     call Crlf

     mov  eax, OFFSET stringSource
     mov  ebx, OFFSET stringTarget
     call ReverseString

     mov  edx, OFFSET stringTargetField
     call WriteString
     mov  edx, OFFSET stringTarget
     call WriteString
     call Crlf
     call Crlf

     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     ; Reverse a byte array demonstration ;
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     mov  edx, OFFSET reverseByteArrayTitle
     call WriteString

     mov  eax, OFFSET byteArraySource
     mov  ebx, OFFSET byteArrayTarget
     mov  ecx, LENGTHOF byteArraySource
     mov  edx, TYPE byteArraySource
     call ReverseArray

     mov  esi, OFFSET byteArrayTarget
     mov  ecx, LENGTHOF byteArrayTarget
     mov  ebx, TYPE byteArrayTarget
     call DumpMem

     call Crlf

     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     ; Reverse a word array demonstration ;
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     mov  edx, OFFSET reverseWordArrayTitle
     call WriteString

     mov  eax, OFFSET wordArraySource
     mov  ebx, OFFSET wordArrayTarget
     mov  ecx, LENGTHOF wordArraySource
     mov  edx, TYPE wordArraySource
     call ReverseArray

     mov  esi, OFFSET wordArrayTarget
     mov  ecx, LENGTHOF wordArrayTarget
     mov  ebx, TYPE wordArrayTarget
     call DumpMem

     call Crlf

     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     ; Reverse a dword array demonstration ;
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     mov  edx, OFFSET reverseDwordArrayTitle
     call WriteString

     mov  eax, OFFSET dwordArraySource
     mov  ebx, OFFSET dwordArrayTarget
     mov  ecx, LENGTHOF dwordArraySource
     mov  edx, TYPE dwordArraySource
     call ReverseArray

     mov  esi, OFFSET dwordArrayTarget
     mov  ecx, LENGTHOF dwordArrayTarget
     mov  ebx, TYPE dwordArrayTarget
     call DumpMem

     call Crlf

     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     call Crlf ; Extra crlf.

     call WaitMsg

     push DWORD PTR 0    ; Exit status code.
     call ExitProcess    ; Exit.
main ENDP

;-----------------------------------------------------
ReverseArray PROC
;
; Reverses an array of elements with identical widths.
; Recieves: EAX -- the input array
;           EBX -- the output array
;           ECX -- the number of elements in the array
;           EDX -- the width of each element in the array
; Returns: Nothing.
;-----------------------------------------------------
     pushfd
     pushad

     mov  esi, eax  ; Copy input array
     mov  edi, edx  ; Copy width for safe keeping

     mov  eax, ecx  ; Copy num of elems into eax for multiplication
     mul  edx       ; (num elems) * width = (bytes in array)
     add  eax, esi  ; (bytes in array) + (offset of input array) = (last address in input array)

     mov  ecx, edi  ; Set parameter for CopyMemory (number of bytes to copy) only once
     mov  edx, edi  ; Restore edx
L1:
     sub  eax, edx  ; Decrement the pointer to the src by the width before calling CopyMemory

     call CopyMemory

     add  ebx, edx  ; Increment the pointer to dest after CopyMemory
     cmp  eax, esi
     jne  L1

     popad
     popfd
     ret
ReverseArray ENDP

;-----------------------------------------------------
CopyMemory PROC
;
; Copy memory of a given length. Is optimized for
; memory lengths that are evenly divisible by 2 or 4.
; Recieves: EAX -- the source memory
;           EBX -- the dest memory
;           ECX -- the number of bytes to copy
;-----------------------------------------------------
     pushfd
     pushad
     
     cld            ; Clear direction flag only once
     mov  esi, eax  ; Set up esi for lodsb/lodsw/lodsd only once

     bt   ecx, 0         ; Test the least significant bit in ecx (bt copies that bit into CF).
     jb   OddNumBytes    ; if CF is set we have an odd number of bytes, so copy each byte one at a time.

     mov  eax, ecx            ; Set dividend to number of bytes to copy.
     xor  edx, edx            ; Clear edx, the upper half of the dividind.
     mov  edi, 4              ; Set the divisor.
     div  edi                 ; Do the division.
     cmp  edx, 0              ; Test the remainder against 0.
     je   DivisibleByFour     ; If remainder is 0 then copy bytes four at a time.

DivisibleByTwo:     ; For aesthetics only.
     mov  eax, ecx  ; Set the dividend to the number of bytes to copy
     xor  edx, edx  ; Clear the upper half of the dividend.
     mov  edi, 2    ; Divide by two.
     div  edi       ; Do the division.
     mov  ecx, eax  ; Move the quotient into ecx = (number of loops)
L2:
     lodsw          ; Copy the word at [esi], and increment esi by two.
     mov  [ebx], ax ; Copy the word into the destination.
     add  ebx, 2    ; Increment ebx to the next word.
     loop L2
     jmp  Cleanup

DivisibleByFour:
     mov  ecx, eax       ; Move the quotient into ecx = (number of loops)
L3:
     lodsd               ; Copy the word at [esi] and increment esi by four.
     mov  [ebx], eax     ; Copy the word into the destination.
     add  ebx, 4         ; Increment ebx to the next dword.
     loop L3
     jmp Cleanup

OddNumBytes:
L1:
     lodsb          ; Load the byte at [esi] and increment esi by one.
     mov  [ebx], al ; Copy the byte into the destination.
     inc  ebx       ; Increment ebx by one.
     loop L1

Cleanup:
     popad
     popfd
     ret
CopyMemory ENDP

;-----------------------------------------------------
ReverseString PROC
;
; Reverses a byte string.
; Note: This procedure will not work with a string
;       larger than 2 GiB, since ecx will sign
;       overflow on repnz scasb.
; Recieves: EAX -- the input string
;           EBX -- the output string
; Returns: Nothing.
;-----------------------------------------------------
     pushfd
     pushad

     mov  edx, eax ; make a copy

     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     ; (1) Find the end of the input string ;
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     mov  edi, eax  ; Set edi for scasb, much like how lodsb uses esi.
     xor  al, al    ; Set al to the value of a nul-byte.
     cld            ; Clear directional flag = increment edi in scasb.
     mov  ecx, -1   ; Set loop counter to negative 1 so repnz continues until ZF is set.
     repnz scasb    ; Load the byte at [edi], test the byte against al -- setting/clearing flags,
                    ; increment edi by one, repeat until ecx is 0 or ZF is set.
     sub  edi, 2    ; We do not want the the address after the nul, nor the nul itself.

     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     ; (2) Copy the string in reverse order ;
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     std            ; Set direction flag indicates to lodsb to decrement esi after copying the byte.
     mov  esi, edi  ; Set esi for lodsb to the last non-nul byte of the input string.
L2:
     lodsb          ; Load the byte into al and decrement esi.
     mov  [ebx], al ; Copy al into the dest string.
     inc  ebx       ; Increment the dest string address.
     cmp  esi, edx  ; Compare the next input address to copy from to the first address of the input string.
     jae  L2        ; Continue copying until esi < edx.

     mov  BYTE PTR [ebx], 0   ; Add the trailing nul to dest

     popad
     popfd
     ret
ReverseString ENDP

END main
