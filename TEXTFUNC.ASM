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

PrintString 		proc                ; C DECL CALL

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

                    _PUSH_ <ax, bx, dx>      ; save regs before Pascal call
                    _PUSH_ <dx, bx>          ; push args
                    CALL Get_Full_TextOffset ; di = full offset of cur line
                    _POP_ <dx, bx, ax>       ; recover regs after Pascal call
                    inc bx                   ; next line

	@@Print_one_char:
                    lodsb                    ; save 1 char in al
                    cmp al, '%'
                    je @@new_line
                    stosw                    ; print 1 char and it`s attribite
					loop @@Print_one_char

    @@end_of_func:
                    _POP_ <di, dx>           ; recover regs
                    pop bp
                    ret    

    @@new_line:
                    dec cx
                    _PUSH_ <ax, bx, dx>      ; save regs before Pascal call
                    _PUSH_ <dx, bx>          ; push args
                    CALL Get_Full_TextOffset ; di = full offset of cur line
                    _POP_ <dx, bx, ax>       ; recover regs after Pascal call
                    inc bx                   ; next line
                    jmp @@Print_one_char

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
; Destr:    bx | dx
; Save:     ax
;------------------------------------------------------------------------------------------------------------------

Get_1_LineOffset_Y  proc
                    PUSH ax

                    mov dx, [Frame0.y0]
                    shl dx, 1            ; dx = 2*Y0

                    mov ax, [Frame0.wid] ; ax = WID
                    or ax, 1             ; make ax odd
                    
                    or bx, 1             ; make bx odd
                    sub ax, bx              
                    add dx, ax            

         			mov ax, dx	    ; ax = y
                    shl dx, 2	    ; dx = 4y
                    add dx, ax	    ; dx = 5y
                    shl dx, 4	    ; dx = 80y = Yoffset   

                    POP ax
                    ret

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

                    mov ax, [Frame0.len] ; ax = LEN
                    or ax, 1             ; make ax odd

                    xor ch, ch
                    mov cl, byte ptr [LineLen_arr + bx] ; cl = len of cur line

                    sub ax, cx  
                    add di, ax  

                    _POP_ <cx, ax>
                    ret
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
; Save:     ax, bx, dx
;------------------------------------------------------------------------------------------------------------------

Get_Full_TextOffset proc                     

                    push bp
                    mov bp, sp

                    CALL Get_TextOffset_X       ; di = hor offest of cur line
                    
                    mov ax, word ptr [bp + 4]   ; ax = y
                    mov dx, ax                  ; dx = y
                    shl dx, 2                   ; dx = 4y
                    add dx, ax                  ; dx = 5y
                    shl dx, 5                   ; dx = 160y

                    mov ax, word ptr [bp + 6]
                    add dx, ax                  ; dx = vert offset of cur line

                    add di, dx                  ; di = full offset 
                    and di, 0FFFEh
                    
                    pop bp
                    ret 4
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
