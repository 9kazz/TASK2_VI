.model tiny
.code
org 100h

;=======================================

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

PRINTB              macro base, offset, char
                    mov byte ptr es:[base + offset], char
                    endm

ARGINIT             macro X0, Y0, length, step
                    mov dx, X0
                    mov si, Y0
                    mov cx, length
                    mov di, step
                    endm

MUL2                macro num1, num2
                    mov ax, num1
                    mul num2
                    mov num1, ax
                    endm

;=======================================

X0                  equ 20
Y0                  equ 10
LEN                 equ 20
WID                 equ 10
HOR_STEP            equ 1
VERT_STEP           equ 80  

Start:              ESVIDMEM

                    ARGINIT X0, Y0, LEN, HOR_STEP   ; upper hor side
                    call PrintLine

                    ARGINIT X0, Y0, WID, VERT_STEP  ; left vert side
                    call PrintLine
                    
                    ARGINIT X0, Y0, LEN, HOR_STEP   ; lower hor side
                    add si, WID                     ; si = Y0 + WID
                    call PrintLine                    
                    
                    ARGINIT X0, Y0, WID, VERT_STEP  ; right vert side
                    add dx, LEN                     ; dx = X0 + LEN
                    call PrintLine 

                    mov dx, X0
                    mov ax, LEN
                    shr ax, 1
                    xor cx, cx
                    mov cl, [bx]    ; cl = com line lenth
                    shr cl, 1       ; cl = 0.5 * com line lenth
                    add dx, ax      
                    sub dx, cx      ; dx = Xtext

                    mov si, Y0
                    mov ax, WID
                    shr ax, 1
                    add si, ax      ; si = Ytext
                    call PrintString                   

                    EXIT


PrintString:		call CalcAdrXY; ax = string start adr in vid mem

					mov si, 80h			; adr of com line lenth
					mov bx, si
					mov cl, [bx]		; cl = com line lenth

	Print_one_symb:
					mov bx, si			; bx = 80h
					mov di, cx			; di = offset in RAM
					mov dl, [bx + di]	; si = char from RAM

					mov bx, ax			; bx = base in VM
					shl di, 1			; di = 2*offset bytes
					PRINTB bx, di, dl	; print char
					inc di				
					PRINTB bx, di, 4ch	; print attribute

					loop Print_one_symb

                    rep ret

PrintLine:          call CalcAdrXY  ; ax = base
                    mov bx, ax      ; bx = base

                    shl di, 1       ; di = 2*offset bytes

    Print_one_char:
                    mov si, cx
                    MUL2 si, di     ; si = 2*offset bytes
                    PRINTW bx, si, 4c03h
                    loop Print_one_char

                    PRINTW bx, 0, 4c03h

                    rep ret


CalcAdrXY:          push si         ; x in dx, y in si
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


end                 Start