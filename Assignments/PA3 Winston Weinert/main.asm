TITLE PA3
; Program Description: Summates a series of integers.
; Author: Winston Weinert
; Creation Date: 3/9/2015

INCLUDE Irvine32.inc

.code
;-----------------------------------------------------
main PROC
;
; Program entry point. Is rather inefficient because
; it stores all the integers in an array and summates
; them after all inputs, but demonstrates how to use
; the heap api.
; Recieves: Nothing.
; Returns:  Nothing.
;-----------------------------------------------------
.data
promptInputNumberOfIntegers   BYTE 'Input number of integers to add: ',0
promptIntPrefix               BYTE 'Int <',0
promptIntSuffix               BYTE '>: ',0
outputTotal                   BYTE 'Total:   ',0
.code
     mov  edx, OFFSET promptInputNumberOfIntegers
     call WriteString
     call ReadInt
     mov  ecx, eax
     call Crlf

     mov  eax, TYPE DWORD     ; Element width.
     mov  ebx, ecx            ; Number of elements.
     call AllocateArray
     mov  esi, eax            ; esi will stay the same.

     xor  edi, edi
L1:
     mov  edx, OFFSET promptIntPrefix
     call WriteString
     mov  eax, edi
     inc  eax                           ; Increment since edi is 0-based.
     call WriteDec                      ; Indicate which number the user is inputting (1...max) in the prompt.
     mov  edx, OFFSET promptIntSuffix
     call WriteString

     call ReadInt
     mov  [esi + edi*TYPE DWORD], eax   ; Save the inputted integer into the array.
     inc  edi
     loop L1

     mov  ecx, ebx       ; Number of integers. esi already contains the offset of the array of integers.
     call SumIntegers

     call Crlf
     mov  edx, OFFSET outputTotal
     call WriteString
     call WriteInt
     call Crlf

     mov  eax, esi
     call FreeArray

     call Crlf
     call WaitMsg

	invoke ExitProcess, 0
main ENDP

;-----------------------------------------------------
SumIntegers PROC
;
; Summates 32-bit integers from an array.
; Recieves: ESI -- address of the array of integers.
;           ECX -- the number of integers.
; Returns:  EAX -- the sum of the integers.
;-----------------------------------------------------
     push ecx
     push edi

     xor  eax, eax  ; Easy debugging.
     xor  edi, edi
L1:
     add  eax, [esi + edi*TYPE DWORD]
     inc  edi
     loop L1

     pop edi
     pop ecx
     ret
SumIntegers ENDP

;-----------------------------------------------------
AllocateArray PROC
;
; Allocate an array using the Process heap object.
; Recieves: EAX -- the width of each array element.
;           EBX -- the number of array elements.
; Returns:  EAX -- pointer to the memory block.
;-----------------------------------------------------
     push ecx  ; Some reason HeapAlloc does not restore the ecx register.
     push edx  ; Since the mul instruction is used, we must restore edx.
     mul  ebx

     push eax                      ; Number of bytes.
     push HEAP_GENERATE_EXCEPTIONS ; Generate exceptions flag.
     call GetProcessHeap
     push eax                      ; Process heap object as returned by GetProcessHeap.
     call HeapAlloc

     pop  edx
     pop  ecx
     ret
AllocateArray ENDP

;-----------------------------------------------------
FreeArray PROC
;
; Free an arrary from the Process heap object.
; Recieves: EAX -- pointer to the memory block.
; Returns:  Nothing.
;-----------------------------------------------------
     push eax

     push eax            ; Pointer to the memory block.
     push DWORD PTR 0    ; No flags.
     call GetProcessHeap
     push eax            ; Heap object handle as returned from GetProcessHeap.
     call HeapFree

     pop  eax
     ret
FreeArray ENDP

END main
