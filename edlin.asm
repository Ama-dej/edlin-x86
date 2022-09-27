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
	je delete

	cmp al, 'i'
	je insert 

	cmp al, 'l'
	je list

	cmp al, 'q' 
	je exit

	inc esi
	dec ecx
	jnz cmds 

	jmp replaceln

;Appends lines to the end of the text until '.' is given. ('a')
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

.aloop:
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
	
	jmp .aloop

delete:
	mov esi, dword[args]

	cmp esi, -1
	jne .nz
	
	mov esi, dword[cur_line]

.nz: 
	cmp esi, 0
	jz mloop

	cmp esi, dword[cur_line]
	jg .no_dec_ln

	dec dword[cur_line]

.no_dec_ln:
	mov eax, fbuf
	mov ecx, esi
	call cntlenln
	push eax
	mov ecx, fbuf

.l:
	cmp byte[ecx + eax], 0x0A
	je .out
	cmp byte[ecx + eax], 0
	jz .out
	inc eax
	jmp .l

.out:
	inc eax
	pop edi
	mov ebx, fbuf
	add ebx, eax 
	sub eax, edi
	mov ecx, ebx
	sub ecx, eax

.l2:
	mov dl, byte[ebx]
	mov byte[ecx], dl	

	cmp dl, 0
	jz mloop

	inc ebx
	inc ecx
	jmp .l2

	jmp mloop
		

;Inserts lines on the current index until '.' is given. (arg0, 'i')
;arg0 defaults to current line
insert:
	mov eax, dword[args]

	cmp eax, -1
	je .chk_if_zero 

	mov dword[cur_line], eax
	jmp .iloop

.chk_if_zero:
	cmp dword[cur_line], 0
	jnz .iloop
	mov dword[cur_line], 1

.iloop:
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

	jmp .iloop

;Lists lines from arg0 to arg1. (arg0, arg1 + 'l')
;arg0 defaults to 10 lines behind the current line.
;arg1 defaults to 20 lines ahead of the current line.
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
	jng .lloop 
	mov edi, eax	
	jmp .lloop

.lloop:
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
	jmp .lloop 

;Replaces the number of the line given. (arg0)
replaceln:
	mov esi, dword[args]

	cmp esi, -1
	je mloop

	cmp esi, 0
	jnz .not_zr 
	mov esi, 1

.not_zr:
	mov eax, fbuf
	call cntln
	inc eax
	cmp esi, eax
	jg entry_err 
	mov dword[cur_line], esi
	je .new_line 
	
	mov eax, esi
	call iprint
	mov eax, ':'
	call putchar
	mov eax, '*'
	call putchar 

.new_line:
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

.rout:
	mov eax, ibuf
	call buf_len

	mov esi, ibuf 

.rcopy:
	mov dl, byte[esi]

	mov byte[edi], dl
	inc esi
	inc edi
	dec eax
	jnz .rcopy

	jmp mloop

;error messages
entry_err:
	mov eax, entry_err_msg
	mov ecx, eax
	call buf_len
	mov edx, eax
	mov eax, 4
	mov ebx, 1
	int 80h

	jmp mloop

inv_input_err:
	mov eax, inv_input_msg
	mov ecx, eax
	call buf_len
	mov edx, eax
	mov eax, 4
	mov ebx, 1
	int 80h

	jmp mloop

;exit (currently spits out technical messages) 
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
	entry_err_msg: db "Entry error.", 0x0A, 0
	inv_input_msg: db "Invalid user input.", 0x0A, 0
	args: times 3 dd -1 
	cur_line: dd 0 
	a_prompt: db " : "
	fbuf: times 1024 * 1024 db 0
	ibuf: times 1024 db 0
