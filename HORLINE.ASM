.model tiny
.code
org 100h

;================================================

Start:			mov ax, 0b800h
			mov es, ax

			xor bx, bx

			mov dx, 15	; y value
			mov di, 40	; starting x
			mov si, 80	; ending x


		        sub si, di	; si = Xmax - Xmin
			mov cx, si	; cx = si = Xmax - Xmin
	  	
			mov ax, dx
			shl ax, 2	; dx = 4y
			add dx, ax	; dx = 5y
			shl dx, 5	; dx = 160y

			mov bx, di 	; bx = Xmin
			add bx, dx	; bx = Xmin + 160y

PrintXY:		mov di, cx
			shl di, 1
			mov word ptr es:[bx + di], 4c03h
			loop PrintXY


			mov ax, 4c00h
			int 21h

end 			Start																		

