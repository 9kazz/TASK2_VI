PrintArt            proc
                    _PUSH_ <bx, dx, si, cx>

                    xor bx, bx
                    mov ah, 07h     ; attribute
                    mov dx, Lines_count

                    jmp @@Print_line

    @@Next_line:    add bx, 2       ; next line in Art_lines_arr

    @@Print_line:   mov si, [Art_lines_arr + bx]
                    mov cx, 80      ; count of chars in one line
                    dec dx          ; dx = the rest strings

    @@Print_char:   lodsb 
                    stosw
                    loop @@Print_char

                    test dx, dx
                    jnz @@Next_line

                    _POP_ <cx, si, dx, bx>
                    ret
                    endp

;------------------------------------------------------------------------------------------------------------------
; Descr:    compares text at the command line with passwor "FRKT" and print ASKII-art if they are same
; Entry:    cx == count of the rest chars in command line
;           si -> cur command line char            
; Exit:     --
; Exp:      es  -> start video memory [b800h]
; Destr:    --
; Save:     cx, es, di, si
;------------------------------------------------------------------------------------------------------------------                    

Check_frkt          proc
                    _PUSH_ <cx, di, si, es>

                    jmp @@Skip_data
                    Password db "FRKT"

    @@Skip_data:    mov di, si                  ; di -> cur com line char
                    mov si, ds
                    mov es, si                  ; es -> data seg
                    mov si, offset Password     ; si -> "FRKT"

                    cmp cx, 4
                    jne @@EOF_Failure

    @@Cmp_one_char: lodsb                       ; compare com line with password
                    scasb
                    jne @@EOF_Failure
                    loop @@Cmp_one_char

                    POP es                      ; recover es -> VM
                    xor di, di                  ; di -> start of the VM
                    CALL PrintArt               ; print FRKT-art
                    jmp @@EOF_Success

    @@EOF_Failure:  _POP_ <es, si, di, cx>   
                    ret     

    @@EOF_Success:  _POP_ <si, di, cx>   
                    POP ax                      ; pop return adr
                    jmp PrintString_EOF         ; exit from PrintString func
                    endp                