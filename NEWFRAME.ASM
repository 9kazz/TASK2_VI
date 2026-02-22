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
; Destr:    --
; Save:     bx, cx, dx, si, di | ax
;------------------------------------------------------------------------------------------------------------------

PrintFrame          proc

                    push bp
                    mov bp, sp          ; save bp

                    _PUSH_ <bx, cx, dx, si, di>  ; save regs

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

                    _POP_ <di, si, dx, cx, bx>  ; recover regs
                    pop bp
                    ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    calculates text`s vertical offset from the start of video memory
; Entry:    bx == count of lines
;           frame coordinates and size as defined constants Y0, WID
;           Y0  == vertical screen offset of rectangle`s upper-left vertex
;           WID == rectangle`s vertical size (is measured in characters)
; Exit:     dx  -- vertical offset in video memmory
; Exp:      defined correct input constants
;           es  -> start video memory [b800h]
; Destr:    | dx
; Save:     ax, bx
;------------------------------------------------------------------------------------------------------------------

Get_1_LineOffset_Y  proc
                    PUSH ax

                    mov dx, [Frame0.y0]
                    shl dx, 1            ; dx = 2*Y0
dd 90909090h
                    mov ax, [Frame0.wid] ; ax = WID
                    test ax, 1h
                    jz @@make_odd
                    
    @@continue:     sub ax, bx              
                    add dx, ax            

         			mov ax, dx	    ; ax = y
                    shl dx, 2	    ; dx = 4y
                    add dx, ax	    ; dx = 5y
                    shl dx, 4	    ; dx = 80y = Yoffset   

                    POP ax
                    ret

    @@make_odd:     dec ax
                    jmp @@continue
                    
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    calculates text`s horizontal offset from the start of video memory
; Entry:    bx == number of the current line
;           frame coordinates and size as defined constants Y0, WID
;           X0  == horizontal screen offset of rectangle`s upper-left vertex
;           LEN == rectangle`s horizontal size (is measured in characters)
; Exit:     di  -- horizontal offset in video memmory
; Exp:      defined correct input constants
;           es  -> start video memory [b800h]
; Destr:    | di
; Save:     ax, cx
;------------------------------------------------------------------------------------------------------------------

Get_TextOffset_X    proc
                    _PUSH_ <ax, cx>

                    mov di, [Frame0.x0]
                    shl di, 1            ; di = 2*X0
dd 90909090h
                    mov ax, [Frame0.len] ; ax = LEN
                    test ax, 1h
                    jz @@make_odd

    @@continue:     xor ch, ch
                    mov cl, byte ptr [LineLen_arr + bx] ; cl = len of cur line

                    sub ax, cx  
                    add di, ax  

                    _POP_ <cx, ax>
                    ret

    @@make_odd:     dec ax
                    jmp @@continue
                    
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    calculates full text`s offset from the start of video memory
; Entry:    dx == vertical offset of the 1st line
;           bx == number of the current line
;           frame coordinates and size as defined constants Y0, WID
;           X0  == horizontal screen offset of rectangle`s upper-left vertex
;           LEN == rectangle`s horizontal size (is measured in characters)
; Exit:     di  -- full offset in video memmory
; Exp:      defined correct input constants
;           es  -> start video memory [b800h]
; Destr:    | di
; Save:     ax, bx
;------------------------------------------------------------------------------------------------------------------

Get_Full_TextOffset proc

                    CALL Get_TextOffset_X    ; di = hor offest of cur line

                    _PUSH_ <ax, bx>
                    
                    mov ax, bx          ; ax = y = bx
                    shl bx, 2           ; bx = 4y
                    add bx, ax          ; bx = 5y
                    shl bx, 5           ; bx = 160y

                    add bx, dx          ; bx = vert offset of cur line
dd 90909090h
                    add di, bx          ; di = full offset 

                    _POP_ <bx, ax>
                    inc bx              ; next line

                    ret
                    endp
;------------------------------------------------------------------------------------------------------------------
; Descr:    prints command line using video memory.
; Entry:    cx  == count of symbols in string
; Exit:     ah  == printing char attribite (can be changed into the function)
;           al  == ASCII of the next character after the string`s last one
;           si  == the first char after the end of the string
;           cx  == the rest length of the command line
; Exp:   1) es  -> start video memory [b800h]
;        2) demands some data in  the stack (Cdecl):
;               1 arg: count of lines
;               2 arg: style
;               3 arg: cur command line adr
; Destr:    ax, bx | si, cx
; Save:     di, dx
;------------------------------------------------------------------------------------------------------------------

PrintString 		proc

                    CALL Skip_space

                    push bp
                    mov bp, sp          ; save bp

                    _PUSH_ <dx, di>     ; save regs

                    test cx, cx         ; if no string to print
                    jz @@end_of_func

                    mov si, [bp + 8]    ; si -> start of com line
                    mov ax, [bp + 6]    ; ax =  store attribite (char will be changed by lodsb)
                    mov bx, [bp + 4]    ; bx =  count of lines

                    CALL Get_1_LineOffset_Y  ; dx = Y offset of 1st line
                    xor bx, bx               ; bx = 0 (new line counter)
                    CALL Get_Full_TextOffset ; di = full offset of cur line

	@@Print_one_char:
                    lodsb               ; save 1 char in al
                    cmp al, '%'
                    je @@new_line
                    stosw               ; print 1 char and it`s attribite
					loop @@Print_one_char

    @@end_of_func:
                    _POP_ <di, dx>      ; recover regs
                    pop bp
                    ret    

    @@new_line:
                    dec cx
                    CALL Get_Full_TextOffset ; di = full offset of cur line
                    jmp @@Print_one_char

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
                    ret
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
; Destr:    ax |
; Save:     bx, dx, cx, si, di 
;------------------------------------------------------------------------------------------------------------------

FillFrame           proc

                    push bp                  ; save bp
                    mov bp, sp

                    _PUSH_ <bx, dx, cx, si, di>     ; save regs

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

                    _POP_ <di, si, cx, dx, bx>  ; recover regs
                    pop bp
                    ret
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
                    _PUSH_ <si, dx>

                    shl dx, 1       ; dx = 2x bytes
         			mov bx, si	    ; bx = y
                    shl si, 2	    ; si = 4y
                    add si, bx	    ; si = 5y
                    shl si, 5	    ; si = 160y bytes
                    
                    mov bx, si
                    add bx, dx

                    _POP_ <dx, si>
                    ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    translate string to number
; Entry:    si -> the string`s start        
;          *cx -- char counter
; Exit:     si -> the next char after the string`s last one
;           dx -- wanted number
;           cx -- is returned less by count of digits in number (and spaces before)
; Exp:      ds -> data segment, which string is contained in
; Destr:    ax | si, dx, cx
; Save:     di
;------------------------------------------------------------------------------------------------------------------

Atoi                proc

                    push di             ; save di

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
                    and ax, 0Fh
                    add dx, ax          ; dx = 10 * cur_sum + cur_digit

                    dec cx
                    jmp @@Read_one_digit


    @@end_proc:     pop di              ; recover di
                    ret
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
                    ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    read style identifier from command line and store it in memory (in ds:[Style_code])
; Entry:    --
; Exit:     ds:[Style_code] : filled struct of style
; Exp:      dx == offset from the start of the array
;           es -> data seg
; Destr:    --
; Save:     si, di, cx, bx
;------------------------------------------------------------------------------------------------------------------

Get_Style           proc

                    _PUSH_ <si, di, cx, bx>         ; save regs

                    shl dx, 3                       ; dx = sizeof(Style_arr) * idx
                    mov bx, dx                      ; bx = offset in arr
                    lea dx, [bx + Style_arr]        ; dx -> Style_arr[idx] 

                    mov si, dx                      ; si -> Style_arr[idx]
                    lea di, [Style_code]            ; di -> Style_code
                    mov cx, 4
                    rep movsw                       ; movs 4 words. *Style_code = Style_arr[idx]

                    _POP_ <bx, cx, di, si>          ; recover regs  

                    ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    recognizes all command line`s flags and execute appropriate proccess
; Entry:    si -> the string`s start        
;           cx -- char counter
; Exit:     si -> the first non-space char
;           cx -- is returned less by count of readed characters
;           ax == 0 guaranteed
; Exp:      --
; Destr:    ax, | si, cx
; Save:     dx, di, es
;------------------------------------------------------------------------------------------------------------------

Get_comline_opt     proc
                    _PUSH_  <dx, di, es>     ; save regs
                    
    @@next_flag:    CALL Get_one_opt
                    test ax, ax              ; if ax-flag == 0, break cycle
                    jnz @@next_flag

                    _POP_ <es, di, dx>       ; recover regs
                    endp


;------------------------------------------------------------------------------------------------------------------
; Descr:    recognizes one command line`s flag and execute appropriate proccess
; Entry:    si -> the string`s start        
;           cx -- char counter
; Exit:     si -> the first non-space char
;           cx -- is returned less by count of readed characters
;           ax -- exit flag: 
;                 ax == 1 -- flag was scanned and executed
;                 ax == 0 -- func don`t find any flags or flag is incorect
; Exp:      --
; Destr:    ax, dx, di, es | si, cx
;------------------------------------------------------------------------------------------------------------------

Get_one_opt     proc

                    _PUSH_  <dx, di, es>     ; save regs

                    CALL Skip_space

                    lodsb       ; al = the next comline`s char
                    cmp al, '-'
                    jne @@not_flag
                    dec cx

                    lodsb       ; al = flag
                    dec cx
                    mov di, ds
                    mov es, di  ; es -> data seg

                    ; SWITCH
                    cmp al, 'x'
                        je @@coordinate_x
                    cmp al, 'y'
                        je @@coordinate_y
                    cmp al, 'l'
                        je @@length
                    cmp al, 'w'
                        je @@width
                    cmp al, 's'
                        je @@style

                    jmp @@default
                    ; END OF SWITCH
                    
    @@switch_end:   mov ax, dx      ; ax = dx = value after flag
                    stosw
                    test ax, ax     ; if ax == 0
                    jnz @@end_of_func
                    inc ax          ; set ax-flag (if ax == 0 before)

    @@end_of_func:  _POP_ <es, di, dx>
                    ret

;-------------------------------------------------------------------

    @@not_flag:     dec si      ; return si to previous char
                    xor ax, ax  ; clear ax-flag (there are no flags)
                    jmp @@end_of_func

                    ; CASES
    @@coordinate_x: lea di, [Frame0.x0]   
                    CALL Atoi   ; dx = value after flag
                    jmp @@switch_end
    
    @@coordinate_y: lea di, [Frame0.y0] 
                    CALL Atoi   ; dx = value after flag      
                    jmp @@switch_end
    
    @@length:       lea di, [Frame0.len]   
                    CALL Atoi   ; dx = value after flag    
                    jmp @@switch_end
    
    @@width:        lea di, [Frame0.wid]   
                    CALL Atoi   ; dx = value after flag
                    jmp @@switch_end                  

    @@style:        CALL Atoi
                    CALL Get_Style   ; ds:[Style_code] : filled struct of style                                                                                      
    ; @@style go though to @@default, then execute jmp @@end_of_func

    @@default:      xor ax, ax       ; clear ax-flag (incorrect flag)
                    jmp @@end_of_func
                    ; END OF CASES

                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    count of lines divided by new line symbol (%) in the printing string
; Entry:    si -> the string`s start        
;           cx -- char counter
; Exit:     bx == count of lines
;           fill LineLen_arr
; Exp:      --
; Destr:    | bx
; Save:     es, di, dx, cx
;------------------------------------------------------------------------------------------------------------------

Count_new_lines     proc

                    CALL Skip_space
                    _PUSH_ <cx, dx, di, es> ; save regs

                    xor dl, dl      ; refresh lenght counter
                    xor bx, bx      ; refresh new line counter

                    mov di, ds
                    mov es, di      ; es -> data seg
                    mov di, si      ; di = si -> cur char in com line
                    mov al, '%'     ; al = divide symbol

	@@check_one_char:
                    scasb
                    je @@inc_newline_counter    ; if char == '%'
                    inc dl                      ; len += 1
					loop @@check_one_char

                    mov byte ptr [LineLen_arr + bx], dl     ; store line length
                    inc bx

    @@end_of_func:
                    _POP_ <es, di, dx, cx>      ; recover regs
                    ret    

    @@inc_newline_counter:
                    mov byte ptr [LineLen_arr + bx], dl     ; store line length
                    xor dl, dl                              ; refresh length counter
                    inc bx
                    dec cx
                    jmp @@check_one_char

                    endp

;===============================================================================================================================================================================================

end                 Start