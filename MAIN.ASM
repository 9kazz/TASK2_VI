.286
.model tiny
.code
org 100h

;===================================================================================================================

locals              @@

ESVIDMEM            macro
                    mov ax, 0b800h
                    mov es, ax
                    endm

EXIT                macro  
                    mov ax, 4c00h
                    int 21h
                    endm

PRINTW              macro base, offset, char
                    mov word ptr es:[base + offset], char
                    endm

CALL_PRINT_LINE     macro X0, Y0, length, step, char
                    mov dx, X0
                    mov si, Y0
                    mov cx, length
                    dec cx          ; sub 1 to fit real size of frame. proc "PrintLine" print one extra char
                    mov di, step
                    push char       ; Cdecl func call
                    call PrintLine
                    pop cx          ; destroy arg
                    endm

_PUSH_              macro args1
                    irp args2, <args1>
                    push args2
                    endm
                    endm

_POP_               macro args1
                    irp args2, <args1>
                    pop args2
                    endm
                    endm

;===================================================================================================================

FramePar_t          struc
    x0              dw 0        ; upper-left vertex coordinate x
    y0              dw 0        ; upper-left vertex coordinate y
    len             dw 0        ; horizontal size (lenth)
    wid             dw 0        ; vertical size (width)
    style           dw 0        ; frame style
FramePar_t          ends
    
Style_t             struc
    frame           dw 02DBh
    fill            dw 0220h
    text            dw 0A3Eh
    feature         dw 0000h
                    ends

HOR_STEP            = 1
VERT_STEP           = 80  

;===================================================================================================================

Start               proc              
                    jmp    @@Skip_Inits

                    Frame0 FramePar_t <10, 10, 15, 5, 0>

                    Style_arr   Style_t <02DBh, 0220h, 0A3Eh, 0000h>
                                Style_t <4c03h or 8000h, 4c00h, 0FFFFh, 0000h>
                                Style_t <8423h, 0420h, 0C21h, 0000h>
                        
                    Style_code  Style_t <,,,>

                    LineLen_arr db 16 dup(0)

    @@Skip_Inits:   call MAIN
                    EXIT
                    endp

                    
MAIN                proc

                    ESVIDMEM

                    xor ch, ch
                    mov cl, ds:[80h]    ; lenth of the command line
                    mov si, 81h         ; start of command line

                    CALL Get_comline_opt            ; si -> the next char after flags

                    mov ax, [Style_code.fill]       ; ax = char & attribute  
                    PUSH ax                         ; FillFrame demands style atr in the stack
                    CALL FillFrame
                    POP ax

                    mov ax, [Style_code.frame]      ; ax = char & attribute   
                    PUSH ax                         ; PrintFrame demands style atr in the stack
                    CALL PrintFrame
                    POP ax

                    CALL Count_new_lines            ; bx = count of lines

                    PUSH si                         ; si -> start of the printing string | Cdecl
                    mov ax, [Style_code.text]       
                    PUSH ax                         ; ax = char & attribute | Cdecl
                    PUSH bx                         ; bx = count of lines | Cdecl
                    CALL PrintString                
                    _POP_ <bx, ax, si>              ; clear the stack

                    ret
                    endp

;===============================================================================================================================================================================================

include FRAMEFUN.ASM    ; frame functions
include TEXTFUNC.ASM    ; text functions
include COMLINEO.ASM    ; command line options
include UTILS.ASM       ; utils

;===============================================================================================================================================================================================

end                 Start