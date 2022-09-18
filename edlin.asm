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

	cmp al, 'd'

	cmp al, 'i'
	je insert 

	cmp al, 'l'
	je list

	cmp al, 'q' 
	je exit

	inc esi
	dec ecx
	jnz cmds 

	jmp replace

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
	mov eax, fbuf
	call cntln

	mov ebx, dword[cur_line]
	mov esi, dword[args]

	cmp esi, -1
	jne .arg1

	mov esi, ebx
	sub esi, 11

.arg1:
	cmp esi, 0
	jnl .nl
	mov esi, 1		
	jmp .nl

.nl:
	mov edi, dword[args+4]
	cmp edi, -1
	jne .arg2

	mov edi, ebx
	add edi, 20 

.arg2:
	cmp edi, eax 
	jng lloop 
	mov edi, eax	
	jmp lloop

lloop:
	cmp esi, edi
	jg mloop

	mov eax, esi
	call iprint

	mov eax, ':'
	call putchar

	mov eax, 0x20 
	cmp esi, dword[cur_line]
	jne .neq
	mov eax, '*' 

.neq:
	call putchar

	mov eax, fbuf
	mov ecx, esi 
	call cntlenln
	add eax, fbuf

	call lnprint

	inc esi
	jmp lloop 

replace:
	mov esi, dword[args]

	cmp esi, -1
	je mloop

	mov dword[cur_line], esi

	mov eax, esi
	call iprint
	mov eax, ':'
	call putchar
	mov eax, '*'
	call putchar 

	call clr_ibuf

	mov eax, fbuf
	mov ecx, esi
	call cntlenln
	push eax
	add eax, fbuf
	mov ecx, eax
	call lnlen

	mov edx, eax
	inc edx
	mov ebx, 1
	mov eax, 4
	int 80h

	mov eax, esi 
	call iprint
	mov eax, ':'
	call putchar
	mov eax, ' '
	call putchar

	mov eax, 3
	mov ebx, 0
	mov ecx, ibuf
	mov edx, 1024
	int 80h

	mov eax, ibuf
	call buf_len
	mov ebx, eax

	pop eax

	mov edi, fbuf 
	add edi, eax

	mov ecx, eax
	mov eax, ibuf
	mov ebx, fbuf
	call adjust


rout:
	mov eax, ibuf
	call buf_len

	mov esi, ibuf 

rcopy:
	mov dl, byte[esi]

	mov byte[edi], dl
	inc esi
	inc edi
	dec eax
	jnz rcopy

	jmp mloop

exit:

	mov ebx, fbuf 

eprint:
	movzx eax, byte[ebx]
	cmp al, 0
	jz reeeeeeEEE 
	
	call putchar
	inc ebx
	jmp eprint

reeeeeeEEE:

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
	a_prompt: db " : "
	fbuf: times 1024 * 1024 db 0
	ibuf: times 1024 db 0
