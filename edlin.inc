clr_ibuf:
	push ebx
	push ecx

	mov ebx, ibuf
	xor ecx, ecx

.clr_L:
	mov byte[ebx + ecx], 0
	inc ecx
	cmp ecx, 1024 
	jl .clr_L

	pop ecx
	pop ebx
	ret

clr_args:
	push eax
	push ecx

	mov ecx, 3
	mov eax, args

.L:
	mov dword[eax], -1
	add eax, 4
	dec ecx
	jnz .L

	pop ecx
	pop eax
	ret

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

iprint:
	pusha

	mov ebx, 10
	xor ecx, ecx	

.div_l:
	xor edx, edx
	idiv ebx

	add edx, 48
	push edx

	inc ecx

	cmp eax, 0
	jnz .div_l

.print_l:
	pop eax
	call putchar
	dec ecx
	jnz .print_l

	popa
	ret	

atoii:
	push ecx
	push edx
	push esi

	mov esi, eax 
	xor eax, eax
	mov ebx, 10

.mul_l:
	movzx ecx, byte[esi]

	cmp cl, 48
	jl .ntnum
	cmp cl, 57
	jg .ntnum

	xor edx, edx
	imul ebx
	sub cl, 48
	add eax, ecx
	inc esi
	jmp .mul_l	

.ntnum:
	mov ebx, esi

	pop esi
	pop edx
	pop ecx
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
