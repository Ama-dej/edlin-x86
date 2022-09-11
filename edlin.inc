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

lnprint:
	push eax
	push ebx
	push ecx
	push edx

	mov ecx, eax
	call lnlen
	mov edx, eax
	inc edx
	mov eax, 4
	mov ebx, 1
	int 80h

	pop edx
	pop ecx
	pop ebx
	pop eax
	ret

lnlen:
	push ebx
	mov ebx, eax

.L:
	cmp byte[eax], 0x0A	
	je .out
	inc eax
	jmp .L

.out:
	sub eax, ebx
	pop ebx
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
	dec ecx
	inc eax
	cmp ecx, 0 
	jg .L1
	jmp .out

.L1:
	cmp byte[eax], 0
	je .out
	cmp byte[eax], 0x0A
	je .L
	inc eax
	jmp .L1

.out:
	sub eax, ebx
	pop ebx
	ret

mv_cpy:
	pusha

	add esi, eax

	mov eax, edi
	call buf_len
	mov ecx, eax

	mov ebx, esi

	mov eax, ebx
	call buf_len ;eax dolz kl bf

	add esi, eax

.mv:
	movzx edx, byte[esi]
	mov byte[esi + ecx], dl

	cmp esi, ebx
	je .cpy

	dec esi
	jmp .mv

.cpy:
	mov dl, byte[edi]
	mov byte[esi], dl
	inc esi
	inc edi
	dec ecx
	jnz .cpy

	popa
	ret

cntln:
	push ebx
	push ecx

	xor ebx, ebx
	xor ecx, ecx

.L:
	mov bl, byte[eax]
	cmp bl, 0
	jz .out

	cmp bl, 0x0A
	jne .inc
	inc ecx

.inc:
	inc eax
	jmp .L

.out:
	mov eax, ecx

	pop ecx
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
