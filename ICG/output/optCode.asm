.MODEL SMALL
.STACK 1000H
.Data
	number DB "00000$"
.CODE
main PROC
	MOV AX, @DATA
	MOV DS,AX
	PUSH BP
	MOV BP,SP
	SUB SP, 2
L1:
	MOV AX,[BP-2]
	PUSH AX
	MOV AX,0	; Line 3
	PUSH AX
	POP BX
	POP AX
	CMP AX,BX
	JG L2
	JMP L3
L2:
	MOV AX,1
	PUSH AX
	JMP L4
L3:
	MOV AX,0
	PUSH AX
L4:
	POP AX
	CMP AX,1
	JE L10
L5:
	MOV AX,[BP-2]
	PUSH AX
	MOV AX,10	; Line 3
	PUSH AX
	POP BX
	POP AX
	CMP AX,BX
	JL L6
	JMP L7
L6:
	MOV AX,1
	PUSH AX
	JMP L8
L7:
	MOV AX,0
	PUSH AX
L8:
L9:
	POP AX 	; Line 3
	CMP AX,1
	JE L10
	JE L10
	JMP L12
	JE L10
L10:
	MOV AX,100	; Line 4
	MOV [BP-2],AX	;Line4
L11:
	JMP L13
L12:
	MOV AX,200	; Line 6
	MOV [BP-2],AX	;Line6
L13:
	MOV AX,[BP-2]
	CALL print_output
	CALL new_line
L14:
	MOV AX,[BP-2]
	PUSH AX
	MOV AX,20	; Line 8
	PUSH AX
	POP BX
	POP AX
	CMP AX,BX
	JG L15
	JMP L16
L15:
	MOV AX,1
	PUSH AX
	JMP L17
L16:
	MOV AX,0
	PUSH AX
L17:
	POP AX
	CMP AX,0
	JE L24
L18:
	MOV AX,[BP-2]
	PUSH AX
	MOV AX,30	; Line 8
	PUSH AX
	POP BX
	POP AX
	CMP AX,BX
	JL L19
	JMP L20
L19:
	MOV AX,1
	PUSH AX
	JMP L21
L20:
	MOV AX,0
	PUSH AX
L21:
	POP AX 	; Line 8
	CMP AX,1
	JE L22
	JE L22
	JMP L24
L22:
	MOV AX,300	; Line 9
	MOV [BP-2],AX	;Line9
L23:
	JMP L25
L24:
	MOV AX,400	; Line 11
	MOV [BP-2],AX	;Line11
L25:
	MOV AX,[BP-2]
	CALL print_output
	CALL new_line
L26:
	MOV AX,[BP-2]
	PUSH AX
	MOV AX,40	; Line 13
	PUSH AX
	POP BX
	POP AX
	CMP AX,BX
	JG L27
	JMP L28
L27:
	MOV AX,1
	PUSH AX
	JMP L29
L28:
	MOV AX,0
	PUSH AX
L29:
	POP AX
	CMP AX,0
	JE L45
L30:
	MOV AX,[BP-2]
	PUSH AX
	MOV AX,50	; Line 13
	PUSH AX
	POP BX
	POP AX
	CMP AX,BX
	JL L31
	JMP L32
L31:
	MOV AX,1
	PUSH AX
	JMP L33
L32:
	MOV AX,0
	PUSH AX
L33:
	POP AX
	CMP AX,1
	JE L43
L34:
	MOV AX,[BP-2]
	PUSH AX
	MOV AX,60	; Line 13
	PUSH AX
	POP BX
	POP AX
	CMP AX,BX
	JL L35
	JMP L36
L35:
	MOV AX,1
	PUSH AX
	JMP L37
L36:
	MOV AX,0
	PUSH AX
L37:
	POP AX
	CMP AX,0
	JE L45
L38:
	MOV AX,[BP-2]
	PUSH AX
	MOV AX,70	; Line 13
	PUSH AX
	POP BX
	POP AX
	CMP AX,BX
	JG L39
	JMP L40
L39:
	MOV AX,1
	PUSH AX
	JMP L41
L40:
	MOV AX,0
	PUSH AX
L41:
L42:
	POP AX 	; Line 13
	CMP AX,1
	JE L43
	JE L43
	JMP L45
	JE L43
L43:
	MOV AX,500	; Line 14
	MOV [BP-2],AX	;Line14
L44:
	JMP L46
L45:
	MOV AX,600	; Line 16
	MOV [BP-2],AX	;Line16
L46:
	MOV AX,[BP-2]
	CALL print_output
	CALL new_line
L47:
	MOV AX,0	; Line 19
	JMP L48
L48:
	ADD SP,2
	POP BP
main ENDP
	MOV AX,4CH
	INT 21H
new_line proc
	push ax
	push dx
	mov ah,2
	mov dl,0Dh
	int 21h
	mov ah,2
	mov dl,0Ah
	int 21h
	pop dx
	pop ax
	ret
new_line endp
print_output proc
	push ax
	push bx
	push cx
	push dx
	push si
	lea si, number
	mov bx, 10
	add si, 4
	cmp ax, 0
	jnge negate
	print:
	xor dx, dx
	div bx
	mov [si], dl
	add [si], '0'
	dec si
	cmp ax, 0
	jne print
	inc si
	lea dx, si
	mov ah, 9
	int 21h
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	negate:
	push ax
	mov ah, 2
	mov dl, '-'
	int 21h
	pop ax
	neg ax
	jmp print
print_output endp
END main
