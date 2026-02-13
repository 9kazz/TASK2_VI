.model tiny
.code
org 100h

Start:	mov ax, 0b800h
	mov es, ax
		
	mov bx, 80	; x
	mov si, 15	; y

	mov cx, si
	shl cx, 2
	add si, cx	; si = 5y
	shl si, 5	; si = 160y
	add bx, si	; bx = x+160y																																																																

	mov word ptr es:[bx], 4c03h

	mov ax, 4c00h
	int 21h	

end 	Start																																																																												