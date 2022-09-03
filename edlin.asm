%include "edlin.inc"

section .text
global _start
_start:

mloop:
	call clr_ibuf

	mov eax, '*'
	call putchar

	mov eax, 3
	mov ebx, 0
	mov ecx, ibuf 
	mov edx, 1024 
	int 80h

	mov esi, ibuf
	xor eax, eax
	mov ecx, 1024 

ploop:
	mov al, [esi]

	cmp al, 'a'	
	je append

	cmp al, 'q' 
	je exit

	inc esi
	dec ecx
	jnz ploop

	jmp mloop	

append:
	mov esi, [cur_index]	

aloop:
	mov eax, 4
	mov ebx, 1
	mov ecx, a_prompt
	mov edx, 3
	int 80h

	call clr_ibuf

	mov eax, 3
	mov ebx, 0
	mov ecx, ibuf
	mov edx, 1024
	int 80h

	mov al, byte[ibuf]
	cmp al, '.'
	je mloop

	mov eax, ibuf 
	call buf_len 
	mov ebx, eax

	mov eax, fbuf
	call buf_len

.mov_fbuf:
	cmp eax, esi
	je .write_fbuf
	mov dl, byte[eax]
	mov byte[eax+ebx], dl	
	dec eax
	jmp .mov_fbuf

.write_fbuf:
	mov eax, esi
	add eax, ebx
	mov ebx, ibuf
	
.l:
	cmp eax, esi
	je .out
	mov dl, byte[ebx]
	mov byte[fbuf+esi], dl 
	inc ebx
	inc esi
	jmp .l

.out:
	mov dword[cur_index], esi

	add eax, 48
	push eax
	mov eax, 4
	mov ebx, 1
	mov ecx, esp
	mov edx, 4 
	int 80h
	pop eax

	jmp aloop

exit:
	mov eax, 4
	mov ebx, 1
	mov ecx, fbuf
	mov edx, 100 
	int 80h

	mov eax, 1
	mov ebx, 0
	int 80h

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

section .data
	cur_line: dd 0
	cur_index: dd 0
	a_prompt: db " : "
	fbuf: times 1024 * 1024 db 0
	ibuf: times 1024 db 0
