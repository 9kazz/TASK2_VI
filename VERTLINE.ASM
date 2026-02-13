.model tiny
.code
org 100h

;================================================

Start:			mov ax, 0b800h
			mov es, ax

			xor bx, bx

			mov dx, 20	; x value
			mov di, 10	; starting y
			mov si, 20	; ending y


		        sub si, di	; si = Ymax - Ymin
			mov cx, si	; cx = si = Ymax - Ymin
	  	
			mov bx, dx 	; bx = x


PrintXY:		mov si, cx
			add si, di	; si = Ymin + Yoffset

			mov ax, si	; ax = si = y
			shl si, 2	; si = 4y
			add si, ax	; si = 5y
			shl si, 5	; si = 160y

			mov word ptr es:[bx + si], 4c03h
			loop PrintXY


			mov ax, 4c00h
			int 21h

end 			Start																		

