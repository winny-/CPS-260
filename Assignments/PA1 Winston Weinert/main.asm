TITLE PA 1
; Program Description: Adds two user specified numbers and prompts to restart.
; Author: Winston Weinert
; Creation Date: Feb 19, 2015

INCLUDE Irvine32.inc

COMMENT !
This is not needed because it is defined in the include file.

.386
.model flat, stdcall
.stack 4096
ExitProcess proto, dwExitCode:dword
!

; Crlf is defined as a proto in Irvine32.inc... thus the trailing underscore.
CRLF_ EQU <0dh, 0ah> 

;-----------------------------------------------------------------------------
.DATA
;-----------------------------------------------------------------------------

greeting            BYTE 'PA1 by Winston Weinert', CRLF_,
                         CRLF_,
                         'This program prompts for two numbers and adds them.', CRLF_,
                         'It then asks if you want to start over.', CRLF_,
                         'Type anything other than y or Y to exit at that point.', CRLF_,
                         CRLF_,
                         0

promptA             BYTE 'a = ', 0
promptB             BYTE 'b = ', 0
promptAddAgain      BYTE 'Add again? (y/n) ', 0

addOutputFormat     BYTE '%d + %d = %d', CRLF_, 0

;-----------------------------------------------------------------------------
.DATA?
;-----------------------------------------------------------------------------

a              DWORD ?
b              DWORD ?
sum            DWORD ?

replyChar      BYTE ?
bufferString   BYTE 100 DUP(?)

;-----------------------------------------------------------------------------
.CODE
;-----------------------------------------------------------------------------

main PROC

     mov  edx, OFFSET greeting
     call WriteString              ; Greet the user.

Beginning:

     mov  edx, OFFSET promptA
     call WriteString              ; Prompt for integer a.

     call ReadInt                  ; Read integer.
     mov  a, eax                   ; Store in a.

     mov  edx, OFFSET promptB
     call WriteString              ; Prompt for integer b.

     call ReadInt                  ; Read integer.
     mov  b, eax                   ; Store in b.

     mov  eax, a
     add  eax, b                   ; Calculate the sum.

     mov  sum, eax                 ; Save sum for later.

     invoke wsprintf,              ; It turns out printf isn't offered in the
            ADDR bufferString,     ; Irvine library, let alone the Windows
            ADDR addOutputFormat,  ; standard libraries. So I used wsprintf --
            a, b, sum              ; sprintf, printf that "prints" to a buffer.

     mov  edx, OFFSET bufferString
     call WriteString              ; Output formatted "a + b = sum".

     call Crlf                     ; Separating line.

     mov  edx, OFFSET promptAddAgain
     call WriteString              ; Display prompt asking to add again?

     call ReadChar                 ; Get a character from input.
     mov  replyChar, al            ; Store in replyChar.

     call WriteChar                ; Echo the inputted character to the user.

     call Crlf                     ; End current line.
     call Crlf                     ; Add separating line.

     cmp  replyChar, 'y'           ; Is replyChar equal to 'y'?
     je   Beginning                ; Then jump to beginning.

     cmp  replyChar, 'Y'           ; Is replyChar equal to 'Y'?
     je   Beginning                ; Then jump to beginning.

     invoke ExitProcess, 0         ; Exit.

main ENDP

END main