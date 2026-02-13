.model tiny
.code
org 100h

;================================================

Start:      		mov ax, 0b800h
	                mov es, ax
	
	                Xmin dw 20
		        Xmax dw 40
		        Ymin dw 10
		        Ymax dw 20

		        mov di, [Ymin]
		        mov si, [Ymax]
		        mov dx, [Xmin]
		        call VertLine   ; left vert side

			mov di, [Ymin]
			mov si, [Ymax]
		        mov dx, [Xmax]
		        call VertLine   ; right vert side

		        mov di, [Xmin]
		        mov si, [Xmax]
		        mov dx, [Ymin]
		        call HorLine   ; upper hor side
			
			mov di, [Xmin]
			mov si, [Xmax]
		        mov dx, [Ymax]
	                call HorLine   ; lower hor side

			mov ax, 4c00h
			int 21h


VertLine:		xor bx, bx

		        sub si, di	; si = Ymax - Ymin
			mov cx, si	; cx = si = Ymax - Ymin
	  	
			mov bx, dx 	; bx = x
			shl bx, 1
			
	VertPrintXY:	mov si, cx
			add si, di	; si = Ymin + Yoffset

			mov ax, si	; ax = si = y
			shl si, 2	; si = 4y
			add si, ax	; si = 5y
			shl si, 5	; si = 160y

			mov word ptr es:[bx + si], 4c03h
			loop VertPrintXY
			mov word ptr es:[bx], 4c03h

           		rep ret


HorLine:		xor bx, bx

		        sub si, di	; si = Xmax - Xmin			
			mov cx, si	; cx = si = Xmax - Xmin
			shl si, 1
			shl di, 1
	  	
			mov ax, dx
			shl ax, 2	; dx = 4y
			add dx, ax	; dx = 5y
			shl dx, 5	; dx = 160y

			mov bx, di 	; bx = Xmin
			add bx, dx	; bx = Xmin + 160y

	HorPrintXY:	mov di, cx
			shl di, 1
			mov word ptr es:[bx + di], 4c03h
			loop HorPrintXY
			mov word ptr es:[bx], 4c03h

           		rep ret

;============================================

end 			Start