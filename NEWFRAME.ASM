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
    frame           dw 4c03h
    fill            dw 0000h
    text            dw 0000h
    feature         dw 0000h
                    ends

HOR_STEP            = 1
VERT_STEP           = 80  

;===================================================================================================================

Start               proc              
                    jmp    @@Skip_Inits

                    Frame0 FramePar_t <10, 10, 15, 5, 0>

                    Style_arr   Style_t <4c03h, 0000h, 0F00h, 0000h>
                                Style_t <4c03h or 8000h, 4c00h, 0FFFFh, 0000h>

                    Style_code  Style_t <,,,>

    @@Skip_Inits:   call MAIN
                    EXIT
                    endp

                    
MAIN                proc

                    ESVIDMEM

                    xor ch, ch
                    mov cl, ds:[80h]    ; lenth of the command line
                    mov si, 81h         ; start of command line

                    CALL Skip_space
                    CALL Atoi

                    shl dx, 3                       ; dx = sizeof(Style_arr) * idx
                    _PUSH_ <si, cx, bx, es, di>     ; save regs
                    mov bx, dx                      ; bx = offset in arr
                    lea dx, [bx + Style_arr]        ; dx -> Style_arr[idx] 

                    mov bx, ds
                    mov es, bx                      ; es -> data seg
                    mov si, dx                      ; si -> Style_arr[idx]
                    lea di, [Style_code]            ; di -> Style_code
                    mov cx, 4
                    rep movsw                       ; movs 4 words. *Style_code = Style_arr[idx]
                    _POP_ <di, es, bx>              ; recover regs (SI, CX -- STAY)

                    mov si, [Style_code.fill]       ; si = char & attribute            
                    push si                
                    CALL FillFrame
                    pop si                 

                    mov si, [Style_code.frame]      ; si = char & attribute            
                    push si               
                    CALL PrintFrame
                    pop si                 

                    pop cx                          ; recover cx
                    CALL Find_Frame_Center
                    mov ax, si                      ; ax = si = Ytext
                    pop si                          ; si = adr of string in command line (but PrintString use si as Ytext)
                    CALL Skip_space

                    push si                         ; si -> start of the printing string
                    mov si, [Style_code.text]       ; si = char & attribute            
                    push si                         
                    mov si, ax                      ; si = ax = Ytext
                    CALL PrintString
                    pop si      
                    pop si

                    rep ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    prints rectangular frame using video memory 
; Entry:    frame coordinates and size as defined constants X0, Y0, LEN, WID:
;           X0  == horizontal screen offset of rectangle`s upper-left vertex
;           Y0  == vertical screen offset of rectangle`s upper-left vertex
;           LEN == rectangle`s horizontal size (is measured in characters)
;           WID == rectangle`s vertical size (is measured in characters)
; Exit:     --
; Exp:   1) difined correct input constants
;        2) es  -> start video memory [b800h]
;        3) get style (char & attribute) by stack (C decl)
; Destr:    bx, cx, dx, si, di
; Save:     ax
;------------------------------------------------------------------------------------------------------------------

PrintFrame          proc

                    push bp
                    mov bp, sp          ; save bp

                    mov ax, [bp + 4]    ; ax = style (char & attribute)

                    CALL_PRINT_LINE [Frame0.x0], [Frame0.y0], [Frame0.len], HOR_STEP, ax      ; upper hor side

                    CALL_PRINT_LINE [Frame0.x0], [Frame0.y0], [Frame0.wid], VERT_STEP, ax     ; left vert side
                    
                    mov bx, [Frame0.y0]        
                    dec bx                                                                    ; sub 1 to fit real size of frame
                    mov si, [Frame0.wid]
                    lea si, [bx + si]                                                         ; si = Y0 + WID - 1
                    CALL_PRINT_LINE [Frame0.x0], si, [Frame0.len], HOR_STEP, ax               ; lower hor side
                    
                    mov bx, [Frame0.x0]   
                    dec bx                                                                    ; sub 1 to fit real size of frame
                    mov si, [Frame0.len]
                    lea dx, [bx + si]                                                         ; dx = X0 + LEN - 1
                    CALL_PRINT_LINE dx, [Frame0.y0], [Frame0.wid], VERT_STEP, ax              ; right vert side

                    pop bp
                    rep ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    calculates offset from the start of video memory according coordinates of frame`s center
; Entry:    cx -- len of the text
;           frame coordinates and size as defined constants X0, Y0, LEN, WID
;           X0  == horizontal screen offset of rectangle`s upper-left vertex
;           Y0  == vertical screen offset of rectangle`s upper-left vertex
;           LEN == rectangle`s horizontal size (is measured in characters)
;           WID == rectangle`s vertical size (is measured in characters)
; Exit:     dx  == horizontal screen offset of frame`s center
;           si  == vertical screen offset of frame`s center
; Exp:      difined correct input constants
;           es  -> start video memory [b800h]
; Destr:    ax | dx, si
; Save:     cx
;------------------------------------------------------------------------------------------------------------------

Find_Frame_Center   proc

                    push cx              ; save cx

                    mov dx, [Frame0.x0]
                    mov ax, [Frame0.len] ; ax = LEN
                    shr ax, 1            ; ax = 0.5 * LEN
                    shr cx, 1            ; cl = 0.5 * com line lenth
                    add dx, ax      
                    sub dx, cx           
                    inc dx               ; dx = Xtext

                    mov si, [Frame0.y0]
                    mov ax, [Frame0.wid] ; ax = WID
                    shr ax, 1            ; ax = 0.5 * WID
                    add si, ax           ; si = Ytext                 

                    pop cx
                    rep ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    prints command line using video memory.
; Entry:    dx  == horizontal screen offset of frame`s center
;           si  == vertical screen offset of frame`s center
;           cx  == count of symbols in string
; Exit:     ah  == printing char attribite (can be changed into the function)
;           al  == ASCII of the next character after the string`s last one
;           si  == the first char after the end of the string
; Exp:   1) es  -> start video memory [b800h]
;        2) get adr of the str`s start and style by stack (C decl)
;               1 arg: style
;               2 arg: start adr
; Destr:    ax, cx, bx, di | dx, si
;------------------------------------------------------------------------------------------------------------------

PrintString 		proc

                    push bp
                    mov bp, sp          ; save bp

                    call CalcAdrXY      ; bx = string start adr in vid mem
                    mov si, [bp + 6]    ; start adr of com line
                    mov di, bx          ; start adr to print string in vid mem
					                    
                    mov ax, [bp + 4]    ; store attribite (char will be changed by loadsb)

	@@Print_one_char:
                    lodsb               ; save 1 char in al
                    stosw               ; print 1 char and it`s attribite
					loop @@Print_one_char

                    pop bp
                    rep ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    prints group of characters with fixed offset into video memory.
; Entry:    dx  == horizontal screen offset of the line`s start
;           si  == vertical screen offset of the line`s start
;           cx  == amount of the characters, which will be printed
;           di  == offset (is measured in charaters) between nearby characters
; Exit:     bx  == address of the first character
;           di  == offset (is measured in bytes) between nearby characters
; Exp:      es  -> start video memory [b800h]
; Destr:    bx, dx | cx, si
; Save:     di
; Note_1:   macros CALL_PRINT_LINEinitialises parameters and then calls the PrintLine function itself.
; Note_2:   constants (HOR_STEP = 1, VERT_STEP = 80) were difined. If parameter STEP = HOR_STEP (VERT_STEP), the horizontal 
;           (vertical) line will be printed.
;------------------------------------------------------------------------------------------------------------------

PrintLine           proc

                    push bp
                    mov bp, sp          ; save bp

                    call CalcAdrXY      ; bx = base
                    mov dx, [bp + 4]    ; dx = char with attribute (1 arg)
                    
                    cmp di, HOR_STEP    ; if di == HOR_STEP
                    je @@hor_line

                    cmp di, VERT_STEP   ; if di == VERT_STEP
                    je @@vert_line

                    jmp @@end_proc

    @@hor_line:     
                    mov si, cx
                    shl si, 1   ; si = 2*cx = 2 * HOR_STEP

                    PRINTW bx, si, dx
                    loop @@hor_line

                    jmp @@end_proc

    @@vert_line:
                    mov si, cx

                    mov di, si          ; di = cx
                    shl si, 2           ; si = 4*cx
                    add si, di          ; si = 5*cx
                    shl si, 5           ; si = 160*cx = 2 * VERT_STEP

                    PRINTW bx, si, dx
                    loop @@vert_line

    @@end_proc:      
                    PRINTW bx, 0, dx
                    pop bp
                    rep ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    fill frame inside by given char
; Entry:    frame coordinates and size as defined constants X0, Y0, LEN, WID
;           X0  == horizontal screen offset of rectangle`s upper-left vertex
;           Y0  == vertical screen offset of rectangle`s upper-left vertex
;           LEN == rectangle`s horizontal size (is measured in characters)
;           WID == rectangle`s vertical size (is measured in characters)
; Exit:     --    
; Exp:   1) es  -> start video memory [b800h]
;        2) get style (char & attribute) by stack (C decl)
; Destr:    ax, bx, dx, cx, si, di |
;------------------------------------------------------------------------------------------------------------------

FillFrame           proc

                    push bp                  ; save bp
                    mov bp, sp

                    mov bp, [bp + 4]         ; !!! BP = style (char & attribute) !!!

                    mov bx, [Frame0.y0]      ; bx = y0
                    mov si, [Frame0.wid]     ; si = wid
                    lea ax, [bx + si]        ; ax = y0 + wid
                    dec ax                   ; ax = y0 + wid - 1             
                                            
    @@Fill_one_line:                        
                    CALL_PRINT_LINE [Frame0.x0], ax, [Frame0.len], HOR_STEP, bp  ; this func changes cx
                    dec ax                                               ;   ~~
                    cmp ax, [Frame0.y0]                                  ;   ^
                    jge  @@Fill_one_line                                 ;   |

                    pop bp
                    rep ret
                    endp


;------------------------------------------------------------------------------------------------------------------
; Descr:    returns offset (is measured in bytes) from the start of video memory according to x-y-coordinates
; Entry:    dx  == horizontal screen offset of frame`s center
;           si  == vertical screen offset of frame`s center
; Exit:     bx  == calculated  offset (is measured in bytes) from the start of video memory
; Exp:      --
; Destr:    --
; Save:     dx, si
;------------------------------------------------------------------------------------------------------------------

CalcAdrXY           proc
                    push si
                    push dx          

                    shl dx, 1       ; dx = 2x bytes
         			mov bx, si	    ; ax = y
                    shl si, 2	    ; si = 4y
                    add si, bx	    ; si = 5y
                    shl si, 5	    ; si = 160y bytes
                    
                    mov bx, dx
                    add bx, si

                    pop dx
                    pop si

                    rep ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    translate string to number
; Entry:    si -> the string`s start        
;           cx -- char counter
; Exit:     si -> the next char after the string`s last one
;           dx -- wanted number
;           cx -- is returned less by count of digits in number (and spaces before)
; Exp:      ds -> data segment, which string is contained in
; Destr:    di, ax | si, dx
;------------------------------------------------------------------------------------------------------------------

Atoi                proc
                    xor dx, dx

                    call Skip_space

    @@Read_one_digit:
                    cmp byte ptr [si], '0'  ; if char is digit
                    jl @@end_proc       
                    cmp byte ptr [si], '9'
                    jg @@end_proc

                    mov di, dx          ; di = cur_sum
                    shl di, 1           ; di = 2 * cur_sum
                    shl dx, 3           ; dx = 8 * cur_sum
                    add dx, di          ; dx = 10 * cur_sum
                    
                    lodsb
                    xor ah, ah
                    sub ax, '0'
                    add dx, ax          ; dx = 10 * cur_sum + cur_digit

                    dec cx
                    jmp @@Read_one_digit


    @@end_proc:     rep ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    skip spaces untill first non-space character
; Entry:    si -> the first char to check out
;           cx -- char counter
; Exit:     si -> the first non-space char
;           cx -- is returned less by count of spaces
; Exp:      --
; Destr:    | si
;------------------------------------------------------------------------------------------------------------------

Skip_space          proc

    @@Skip_one_space:
                    cmp byte ptr [si], ' '  ; if char is space
                    jne @@end_proc
                    inc si                  ; next char
                    dec cx
                    jmp @@Skip_one_space
                    
    @@end_proc:
                    rep ret
                    endp

;===============================================================================================================================================================================================

end                 Start