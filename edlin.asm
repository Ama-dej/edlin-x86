%include "edlin.inc"

section .text
global _start
_start:

mloop:
	call clr_ibuf
	call clr_args

	mov eax, '*'
	call putchar

	mov eax, 3
	mov ebx, 0
	mov ecx, ibuf 
	mov edx, 1024 
	int 80h

	mov esi, ibuf
	mov eax, esi 
	mov ecx, 1024 
	mov edx, args	

	cmp byte[esi], 48
	jl cmds
	cmp byte[esi], 57
	jg cmds

ploop:
	call atoii

	cmp edx, cur_line
	je cmds 
	mov dword[edx], eax
	add edx, 4

	mov eax, ebx
	inc eax

	cmp byte[ebx], ','
	je ploop

	mov esi, eax
	dec esi

cmds:
	movzx eax, byte[esi]

	cmp al, 'a'
	je append

	cmp al, 'i'
	je insert 

	cmp al, 'l'
	je list

	cmp al, 'q' 
	je exit

	inc esi
	dec ecx
	jnz cmds 

	jmp mloop

append:
	mov eax, fbuf
	mov ebx, eax
	xor ecx, ecx

.loolp:
	mov dl, byte[eax]

	cmp dl, 0x0A
	jne .naprej
	inc ecx

.naprej:	
	cmp dl, 0
	jz .out
	inc eax
	jmp .loolp

.out:
	sub eax, ebx
	mov esi, eax
	mov dword[cur_line], ecx

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

	push esi

	mov eax, esi
	mov esi, fbuf
	mov edi, ibuf
	call mv_cpy

	pop esi

	mov eax, ibuf
	call buf_len
	add esi, eax

	inc dword[cur_line]
	
	jmp aloop

insert:
	mov eax, dword[args]

	cmp eax, -1
	je .chk_if_zero 

	mov dword[cur_line], eax
	jmp iloop

.chk_if_zero:
	cmp dword[cur_line], 0
	jnz iloop
	mov dword[cur_line], 1

iloop:
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

	mov eax, fbuf
	mov ecx, dword[cur_line]
	call cntlenln

	;vrednost eax-a ze prhaja od cntlenln 
	mov esi, fbuf
	mov edi, ibuf
	call mv_cpy

	inc dword[cur_line]

	jmp iloop

list:
	mov esi, dword[cur_index]
	mov edx, 10
	mov ecx, 0

	jmp mloop

exit:
	mov eax, 4
	mov ebx, 1
	mov ecx, fbuf
	mov edx, 100 
	int 80h

	mov eax, [args]
	call hprintln 
	mov eax, [args+4]
	call hprintln
	mov eax, [args+8]
	call hprintln

	mov eax, [cur_line]
	call iprint

	mov eax, 0x0A
	call putchar

	mov eax, 1
	mov ebx, 0
	int 80h

section .data
	args: times 3 dd -1 
	cur_line: dd 0 
	cur_index: dd 0
	a_prompt: db " : "
	fbuf: times 1024 * 1024 db 0
	ibuf: times 1024 db 0
