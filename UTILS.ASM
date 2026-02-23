
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
