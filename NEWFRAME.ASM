.model tiny
.code
org 100h

;=======================================

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

CALL_PRINTLINE      macro X0, Y0, length, step
                    mov dx, X0
                    mov si, Y0
                    mov cx, length
                    dec cx          ; sub 1 to fit real size of frame. proc "PrintLine" print one extra char
                    mov di, step
                    call PrintLine
                    endm

MUL2                macro num1, num2
                    mov ax, num1
                    mul num2
                    mov num1, ax
                    endm

;=======================================

FramePar_t          struc
    x0              dw 0        ; upper-left vertex coordinate x
    y0              dw 0        ; upper-left vertex coordinate y
    len             dw 0        ; horizontal size (lenth)
    wid             dw 0        ; vertical size (width)
    fill            dw 4c00h    ; chars to filling and its attribite
    style           dw 0        ; frame style
FramePar_t          ends
    
HOR_STEP            = 1
VERT_STEP           = 80  

;=======================================

Start:              
                    jmp    @@Skip_Inits
                    Frame0 FramePar_t <10, 10, 5, 5, 4c00h, 0>
    @@Skip_Inits:              
                    ESVIDMEM

                    call FillFrame
                    call PrintFrame
                    call Find_Frame_Center
                    call PrintString  

                    EXIT

;------------------------------------------------------------------------------------------------------------------
; Descr:    prints rectangular frame using video memory 
; Entry:    frame coordinates and size as defined constants X0, Y0, LEN, WID
;           X0  == horizontal screen offset of rectangle`s upper-left vertex
;           Y0  == vertical screen offset of rectangle`s upper-left vertex
;           LEN == rectangle`s horizontal size (is measured in characters)
;           WID == rectangle`s vertical size (is measured in characters)
; Exit:     --
; Exp:      difined correct input constants
; Exp:      es --> start video memory [b800h]
; Destr:    ax,bx, cx, dx, si, di
;------------------------------------------------------------------------------------------------------------------

PrintFrame         proc

                    CALL_PRINTLINE [Frame0.x0], [Frame0.y0], [Frame0.len], HOR_STEP   ; upper hor side

                    CALL_PRINTLINE [Frame0.x0], [Frame0.y0], [Frame0.wid], VERT_STEP  ; left vert side
                    
                    mov bx, [Frame0.y0]        
                    dec bx                                                            ; sub 1 to fit real size of frame
                    mov si, [Frame0.wid]
                    lea si, [bx + si]                                                 ; si = Y0 + WID - 1
                    CALL_PRINTLINE [Frame0.x0], si, [Frame0.len], HOR_STEP            ; lower hor side
                    
                    mov bx, [Frame0.x0]   
                    dec bx                                                            ; sub 1 to fit real size of frame
                    mov si, [Frame0.len]
                    lea dx, [bx + si]                                                 ; dx = X0 + LEN - 1
                    CALL_PRINTLINE dx, [Frame0.y0], [Frame0.wid], VERT_STEP           ; right vert side

                    rep ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    calculates offset from the start of video memory according coordinates of frame`s center
; Entry:    frame coordinates and size as defined constants X0, Y0, LEN, WID
;           X0  == horizontal screen offset of rectangle`s upper-left vertex
;           Y0  == vertical screen offset of rectangle`s upper-left vertex
;           LEN == rectangle`s horizontal size (is measured in characters)
;           WID == rectangle`s vertical size (is measured in characters)
; Exit:     dx  == horizontal screen offset of frame`s center
;           si  == vertical screen offset of frame`s center
; Exp:      difined correct input constants
;           es --> start video memory [b800h]
; Destr:    ax, cx
;------------------------------------------------------------------------------------------------------------------

Find_Frame_Center   proc

                    mov dx, [Frame0.x0]
                    mov ax, [Frame0.len] ; ax = LEN
                    shr ax, 1            ; ax = 0.5 * LEN
                    xor cx, cx
                    mov cl, ds:[80h]     ; cl = com line lenth
                    shr cl, 1            ; cl = 0.5 * com line lenth
                    add dx, ax      
                    sub dx, cx           ; dx = Xtext

                    mov si, [Frame0.y0]
                    mov ax, [Frame0.wid]  ; ax = WID
                    shr ax, 1             ; ax = 0.5 * WID
                    add si, ax            ; si = Ytext                 

                    rep ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    prints command line using video memory.
; Entry:    dx  == horizontal screen offset of frame`s center
;           si  == vertical screen offset of frame`s center
; Exit:     ah  == printing char attribite (can be changed into the function)
;           al  == ASCII of the next character after the string`s last one
;           cl  == address of command line`s start in ds (82h). Skip extra space (real address is 81h).
; Exp:      es --> start video memory [b800h]
; Destr:    ax, cx, bx | dx, si
;------------------------------------------------------------------------------------------------------------------

PrintString 		proc
                    call CalcAdrXY      ; bx = string start adr in vid mem
                    xor cx, cx
					mov cl, ds:[80h]  	; cl = com line lenth
                    dec cl              ; do not count extra space
                    mov si, 82h         ; start adr of com line (without extra space)
                    mov di, bx          ; start adr to print string in vid mem

	@@Print_one_char:
					mov ah, 4ch         ; store attribite
                    lodsb               ; save 1 char in al
                    stosw               ; print 1 char and it`s attribite
					loop @@Print_one_char

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
; Exp:      es --> start video memory [b800h]
; Destr:    bx | cx, si
; Save:     dx, di
; Note_1:   macro CALL_PRINTLINE initialises parameters and then calls the PrintLine function itself.
; Note_2:   constants (HOR_STEP = 1, VERT_STEP = 80) were difined. If parameter STEP = HOR_STEP (VERT_STEP), the horizontal 
;           (vertical) line will be printed.
;------------------------------------------------------------------------------------------------------------------

PrintLine           proc

                    call CalcAdrXY      ; bx = base
                    
                    cmp di, HOR_STEP    ; if di == HOR_STEP
                    je @@hor_line

                    cmp di, VERT_STEP   ; if di == VERT_STEP
                    je @@vert_line

                    jmp @@end_proc

    @@hor_line:     
                    mov si, cx
                    shl si, 1   ; si = 2*cx = 2 * HOR_STEP

                    PRINTW bx, si, 4c03h
                    loop @@hor_line

                    jmp @@end_proc

    @@vert_line:
                    mov si, cx

                    mov di, si          ; di = cx
                    shl si, 2           ; si = 4*cx
                    add si, di          ; si = 5*cx
                    shl si, 5           ; si = 160*cx = 2 * VERT_STEP

                    PRINTW bx, si, 4c03h
                    loop @@vert_line

    @@end_proc:      
                    PRINTW bx, 0, 4c03h
                    rep ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    
; Entry:              
; Exit:     
; Exp:      
; Destr:    
;------------------------------------------------------------------------------------------------------------------

FillFrame          proc

                   mov bx, [Frame0.y0]      ; bx = y0
                   mov si, [Frame0.wid]     ; si = wid
                   lea ax, [bx + si]        ; ax = y0 + wid
                   dec ax                   ; ax = y0 + wid - 1

    @@Fill_one_line:
                    CALL_PRINTLINE [Frame0.x0], ax, [Frame0.len], HOR_STEP  ; this func changes cx
                    dec ax
                    cmp ax, [Frame0.y0]
                    jge  @@Fill_one_line

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

end                 Start