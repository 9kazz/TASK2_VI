.model tiny
.code
org 100h

;=================================

ESVIDMEM            macro
                    mov ax, 0b800h
                    mov es, ax
                    endm

EXIT                macro  
                    mov ax, 4c00h
                    int 21h
                    endm

PRINTB              macro base, offset, char
                    mov byte ptr es:[base + offset], char
                    endm

;=================================

X0 					equ 10
Y0					equ 5

Start:				ESVIDMEM

					mov dx, X0
					mov si, Y0
					call CalcAdrXY; ax = string start adr in vid mem

					mov si, 80h			; adr of com line lenth
					mov bx, si
					mov cl, [bx]		; cl = com line lenth

	PrintString:
					mov bx, si			; bx = 80h
					mov di, cx			; di = offset in RAM
					mov dl, [bx + di]	; si = char from RAM

					mov bx, ax			; bx = base in VM
					shl di, 1			; di = 2*offset bytes
					PRINTB bx, di, dl	; print char
					inc di				
					PRINTB bx, di, 4ch	; print attribute

					loop PrintString

					EXIT


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


end 		Start 
		

		