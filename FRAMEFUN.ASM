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
