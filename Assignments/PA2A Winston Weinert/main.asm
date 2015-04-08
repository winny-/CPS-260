TITLE PA2A
; Program Description: Converts a DWORD between little-endian and big-endian.
; Author: Winston Weinert
; Creation Date: 3/12/2015

INCLUDE Irvine32.inc

OPTION CASEMAP:NONE ; Force case sensitivity.

.data
bigEndian      BYTE 12h,34h,56h,78h
beString       BYTE 'BE (hex) = ',0
leString       BYTE 'LE (hex) = ',0
usingA         BYTE ' (using memory-based array arithmetic -- 24 instructions)',0
usingB         BYTE ' (using rol -- 4 instructions)',0
usingC         BYTE ' (using bswap -- 2 instructions)',0

.data?
buf            DWORD ?

.code
main PROC
     ; Output: BE (hex) =
     mov  edx, OFFSET beString
     call WriteString

     ; Output: 12 34 56 78
     mov  eax, OFFSET bigEndian
     mov  ecx, SIZEOF bigEndian    ; Same thing as TYPE DWORD, but indicates that the original data is an array of bytes.
     call WriteHexBytes

     call Crlf

     ; Output: LE (hex) =
     mov  edx, OFFSET leString
     call WriteString

     ; Output: 78 56 34 12
     mov  eax, DWORD PTR bigEndian
     call FlipDWordByteOrderA      ; Reverse bytes using memory-based array arithmetic.
     mov  buf, eax                 ; Store in buf, since WriteHexBytes takes a memory location.
     mov  eax, OFFSET buf
     mov  ecx, TYPE DWORD
     call WriteHexBytes

     ; Output:  (using memory-based array arithmetic -- 24 instructions)
     mov  edx, OFFSET usingA       ; Note how this worked.
     call WriteString

     call Crlf

     ; Output: LE (hex) =
     mov  edx, OFFSET leString
     call WriteString

     ; Output: 78 56 34 12
     mov  eax, DWORD PTR bigEndian
     call FlipDWordByteOrderB      ; Reverse bytes using rol, no memory access.
     mov  buf, eax                 ; Store in buf, since WriteHexBytes takes a memory location.
     mov  eax, OFFSET buf
     mov  ecx, TYPE DWORD
     call WriteHexBytes

     ; Output:  (using arithemtic shifts -- 14 instructions)
     mov  edx, OFFSET usingB       ; Note how this worked.
     call WriteString

     call Crlf

     ; Output: LE (hex) =
     mov  edx, OFFSET leString
     call WriteString

     ; Output: 78 56 34 12
     mov  eax, DWORD PTR bigEndian
     call FlipDWordByteOrderC      ; Reverse bytes using bswap instruction. Uses no memory and requires no register cleanup.
     mov  buf, eax                 ; Store in buf, since WriteHexBytes takes a memory location.
     mov  eax, OFFSET buf
     mov  ecx, TYPE DWORD
     call WriteHexBytes

     ; Output:  (using bswap instruction -- 2 instructions)
     mov  edx, OFFSET usingC       ; Note how this worked.
     call WriteString

     call Crlf

     call Crlf ; Empty line separating program output from 'Press any key to continue...'

     call WaitMsg

     invoke ExitProcess, 0    ; Exit.
main ENDP

;-----------------------------------------------------
FlipDWordByteOrderA PROC
;
; Reverses the byte-order of a dword. It is 
; endianness-naive. It simply reverses the bytes.
; Receives: EAX -- the dword to operate on.
; Returns:  EAX -- the dword with its byte-order
;                  reversed.
;-----------------------------------------------------
.data?
inputDWord     DWORD ?
outputDWord    DWORD ?

.code
     pushad                        ; Save registers.

     mov  inputDWord, eax          ; Save the input.
     mov  esi, OFFSET inputDWord   ; esi will be the loop counter that increments.
     mov  ecx, TYPE inputDWord     ; Set the loop to iterate 4 times. ecx will be the loop counter that decrements.
     xor  edx, edx                 ; Clear edx to make debugging easier, since this way only dl has non-zero data.

L1:
     mov  dl, BYTE PTR [esi]                 ; Copy the byte esi points at to dl.
     mov  BYTE PTR [outputDWord + ecx-1], dl ; Need to subtract 1 from
                                             ; ecx to fix the address offset,
                                             ; Since the values of ecx in this
                                             ; loop are 4, 3, 2, 1.

     inc esi   ; Increment the esi loop counter.
     loop L1   ; Decrement ecx loop counter and loop if it is 0<.

     popad                    ; Restore registers.
     mov  eax, outputDWord    ; Set the output register edx.
     ret                      ; Return control to caller.
FlipDWordByteOrderA ENDP

;-----------------------------------------------------
FlipDWordByteOrderB PROC
;
; Flip the bytes in a DWord. Is endianness naive.
; This should be faster that FLipDWordByteOrderA,
; since it does not use memory access.
; Recieves: EAX -- the DWord to flip bytes on.
; Returns:  EAX -- the flipped DWord
;-----------------------------------------------------
     rol  ax, 8     ; Flip the two lower bytes.
     rol  eax, 16   ; Rotate the two least significant bytes, thereby rotating the two most significant bytes into ax.
     rol  ax, 8     ; Flp the original higher two bytes.
     ret            ; Return to caller.
FlipDWordByteOrderB ENDP

;-----------------------------------------------------
FlipDWordByteOrderC PROC
;
; Flip the byte-order in a DWord. This is faster than
; both FlipDWordByteOrderA and FlipDWordByteOrderB.
; Recieves: EAX -- the DWord that should have its
;                  bytes reversed.
; Returns:  EAX -- the output.
;-----------------------------------------------------
     bswap eax
     ret
FlipDWordByteOrderC ENDP

;-----------------------------------------------------
WriteHexBytes PROC
;
; Print an array of hex bytes separated by a single
; space. Depends on Irvine32.
; Receives: EAX -- the offset of the bytes to print.
;           ECX -- the number of bytes to print,
;                  starting at EAX.
; Returns: nothing.
;-----------------------------------------------------
     pushad    ; Save registers.

     mov  esi, eax       ; Hold the first address in esi.
     add  ecx, esi       ; Hold the last address to write in ecx.
     mov  ebx, TYPE BYTE ; Used by WriteHexB, and since we are only working with bytes, set this register once.
     cld

L1:
     lodsb               ; Copy byte at [esi] into al and increment esi.
     call WriteHexB      ; Write the byte from al, size of data to write in ebx (TYPE BYTE).

     cmp  esi, ecx       ; Are all bytes written?
     je   L2             ; If so, do not write a trailing space, and jump past the unconditional jump.

     mov  al, ' '
     call WriteChar      ; Separate bytes with a single space.

     jmp  L1             ; Unconditional jump to L1.

L2:
     popad     ; Restore registers.
     ret       ; Return control to caller.
WriteHexBytes ENDP

END main
