hprintln:
	pusha 

	mov esi, hex_digits
	mov edi, hex_reg
	mov ecx, 8
	
.L:
	rol eax, 4
	movzx ebx, al 
	and bl, 0x0F
	mov bl, byte[ebx + esi] 
	mov byte[edi], bl
	inc edi
	dec ecx
	jnz .L

	mov eax, 4
	mov ebx, 1
	mov ecx, swag_formatting 
	mov edx, 11 
	int 80h

	popa
	ret

putchar:
	push edx
	push ecx
	push ebx
	push eax
	
	mov eax, 4
	mov ebx, 1
	mov ecx, esp
	mov edx, 4
	int 80h

	pop eax
	pop ebx
	pop ecx
	pop edx
	ret

cntlenln:
	push ebx
	mov ebx, eax
	dec eax

.L:
	inc eax
	cmp byte[eax], 0x0A
	jne .L

	dec ecx
	cmp ecx, 0
	jnl .L

	sub eax, ebx
	inc eax
	pop ebx
	ret

buf_len:
	push ebx
	mov ebx, eax

.L:
	cmp byte[eax], 0
	jz .out
	inc eax
	jmp .L

.out:
	sub eax, ebx
	pop ebx
	ret

section .data
	hex_digits: db "0123456789ABCDEF"
	swag_formatting: db "0x"
	hex_reg: db "00000000", 0ah
