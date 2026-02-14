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
                    mov cx, length - 1      ; sub 1 to fit real size of frame. proc "PrintLine" print one extra char
                    mov di, step
                    call PrintLine
                    endm

MUL2                macro num1, num2
                    mov ax, num1
                    mul num2
                    mov num1, ax
                    endm

;=======================================

X0                  = 20
Y0                  = 8
LEN                 = 24
WID                 = 8
HOR_STEP            = 1
VERT_STEP           = 80  

Start:              ESVIDMEM
                    call Print_Frame
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

Print_Frame         proc

                    CALL_PRINTLINE X0, Y0, LEN, HOR_STEP   ; upper hor side

                    CALL_PRINTLINE X0, Y0, WID, VERT_STEP  ; left vert side
                    
                    mov si, Y0 + WID-1                     ; si = Y0 + WID. sub 1 to fit real size of frame 
                    CALL_PRINTLINE X0, si, LEN, HOR_STEP   ; lower hor side
                    
                    mov dx, X0 + LEN-1                     ; dx = X0 + LEN. sub 1 to fit real size of frame
                    CALL_PRINTLINE dx, Y0, WID, VERT_STEP  ; right vert side

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

                    mov dx, X0
                    mov ax, LEN          ; ax = LEN
                    shr ax, 1            ; ax = 0.5 * LEN
                    xor cx, cx
                    mov cl, ds:[80h]     ; cl = com line lenth
                    shr cl, 1            ; cl = 0.5 * com line lenth
                    add dx, ax      
                    sub dx, cx           ; dx = Xtext

                    mov si, Y0
                    mov ax, WID           ; ax = WID
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
; Destr:    ax, cx
;------------------------------------------------------------------------------------------------------------------

PrintString 		proc
                    call CalcAdrXY      ; ax = string start adr in vid mem
                    xor cx, cx
					mov cl, ds:[80h]  	; cl = com line lenth
                    dec cl              ; do not count extra space
                    mov si, 82h         ; start adr of com line (without extra space)
                    mov di, ax          ; start adr to print string in vid mem

	@@Print_one_char:
					mov ah, 4ch         ; store attribite
                    lodsb               ; save 1 char in al
                    stosw               ; print 1 char and it`s attribite
					loop @@Print_one_char

                    rep ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    prints group of characters with fixed offset into video memory.
; Entry:    dx  == horizontal screen offset of frame`s center
;           si  == vertical screen offset of frame`s center
;           cx  == amount of the characters, which will be printed
;           di  == offset (is measured in charaters) between nearby characters
; Exit:     ax  == address of the first character
;           di  == offset (is measured in bytes) between nearby characters
; Exp:      es --> start video memory [b800h]
; Destr:    ax, cx
; Note:     macro CALL_PRINTLINE initialises parameters and then calls the PrintLine function itself.
;------------------------------------------------------------------------------------------------------------------

PrintLine           proc
                    call CalcAdrXY  ; ax = base
                    mov bx, ax      ; bx = base

                    shl di, 1       ; di = 2*offset bytes

    @@Print_one_char:
                    mov si, cx
                    MUL2 si, di     ; si = 2*offset bytes
                    PRINTW bx, si, 4c03h
                    loop @@Print_one_char

                    PRINTW bx, 0, 4c03h

                    rep ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    returns offset (is measured in bytes) from the start of video memory according to x-y-coordinates
; Entry:    dx  == horizontal screen offset of frame`s center
;           si  == vertical screen offset of frame`s center
; Exit:     ax  == calculated  offset (is measured in bytes) from the start of video memory
; Exp:      --
; Destr:    --
;------------------------------------------------------------------------------------------------------------------

CalcAdrXY           proc
                    push si
                    push dx          

                    shl dx, 1       ; dx = 2x bytes
         			mov ax, si	    ; ax = y
                    shl si, 2	    ; si = 4y
                    add si, ax	    ; si = 5y
                    shl si, 5	    ; si = 160y bytes
                    
                    mov ax, dx
                    add ax, si

                    pop dx
                    pop si

                    rep ret
                    endp

end                 Start