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

    @@default:      xor ax, ax       ; clear ax-flag (incorrect flag)
                    jmp @@end_of_func
                    ; END OF CASES

                    endp
