%include "edlin.inc"

section .text
global _start
_start:
	mov dword[cur_line], 0

	mov eax, 5
	mov ebx, file_name
	mov ecx, 2
	int 80h

	mov dword[f_dscrptor], eax

	mov ebx, eax 
	mov eax, 3
	mov ecx, fbuf
	mov edx, 1024 * 1024
	int 80h

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
	mov al, byte[esi]

	cmp al, 'a'
	je append

	cmp al, 'd'
	je delete

	cmp al, 'e'
	je eksit 

	cmp al, 'i'
	je insert 

	cmp al, 'l'
	je list

	cmp al, 'q' 
	je quit 

	cmp al, 's'
	je search

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


;Deletes lines from 1st index to 2nd index with both points included (arg0, arg1 + 'd').
;If only arg0 is given it deletes the line on that index.
;arg0 defaults to current line.
delete:
	mov esi, dword[args]

	cmp esi, -1 
	jg .nz

	mov esi, dword[cur_line]

.nz: 
	cmp esi, 0
	jz mloop

	mov edi, dword[args+4]
	cmp edi, -1 
	jg .nmo

	mov edi, esi

.nmo:
	mov ecx, dword[cur_line]

	cmp ecx, esi
	jl .del	

	cmp ecx, edi
	jle .jmp_bck 

	mov ebx, edi 
	sub ebx, esi
	inc ebx
	sub dword[cur_line], ebx

	jmp .del		

.jmp_bck:
	sub ecx, esi
	inc ecx

	sub dword[cur_line], ecx

.del:
	sub edi, esi
	inc edi

	mov eax, fbuf
	mov ecx, esi
	call cntlenln

	push eax
	mov ecx, fbuf
	dec eax

.chk_pos:
	inc eax
	dec edi
	cmp edi, 0
	jl .out

.l:
	cmp byte[ecx + eax], 0x0A
	je .chk_pos
	cmp byte[ecx + eax], 0
	jz .out
	inc eax
	jmp .l

.out:
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


;Exits and saves the file ('e').
eksit:
	mov eax, 10
	mov ebx, file_name
	int 80h

	mov eax, 8
	mov ebx, file_name
	mov ecx, 0664o
	int 80h

	mov dword[f_dscrptor], eax

	mov eax, fbuf
	call buf_len

	mov edx, eax
	mov eax, 4
	mov ebx, dword[f_dscrptor]
	mov ecx, fbuf
	int 80h

	jmp quit 

;Inserts lines on the current index until '.' is given. (arg0 + 'i')
;arg0 defaults to current line
insert:
	mov eax, dword[args]

	cmp eax, 0 
	jl .iloop 

	mov dword[cur_line], eax

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

	cmp esi, 0
	jl mloop

	;cmp esi, 0
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
quit:
	mov eax, 6
	mov ebx, dword[f_dscrptor]
	int 80h
	
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

;Searches for the first match for the text given. (arg0, arg1 + 's' + string)
;If only arg0 is given or no arguments are given it searches from the current line incrementally.
search:
	mov esi, dword[args]
	mov edi, dword[args+4]

	cmp esi, -1 
	jg .esi_ok

	mov esi, dword[cur_line]

.esi_ok:
	mov edx, ibuf

	cmp esi, 0
	jnz .esi_bigr?

	inc esi

.esi_bigr?:
	cmp esi, edi
	jg .nf	

.find_s:
	cmp byte[edx], 's'
	je .found_s	
	inc edx
	jmp .find_s

.found_s:
	inc edx
	mov eax, fbuf
	mov ecx, esi
	call cntlenln

	mov ecx, eax

	mov eax, edx
	call buf_len
	dec eax
	mov byte[edx+eax], 0

.sloop:
	mov eax, ecx
	add eax, fbuf
	cmp byte[eax], 0
	jz .nf
	cmp byte[eax], 0x0A
	jne .no_nl

	cmp esi, edi
	je .nf

	inc esi

.no_nl:
	push ecx

	mov eax, edx
	mov ebx, fbuf
	call strcmp

	pop ecx

	inc ecx

	cmp eax, 0
	jz .sloop

	mov dword[cur_line], esi

	mov eax, esi
	call iprint

	mov eax, ':'
	call putchar
	mov eax, '*'
	call putchar

	add ecx, fbuf
	dec ecx
	mov eax, ecx
	call lnprint

	jmp mloop

.nf:	
	mov eax, 4
	mov ebx, 1
	mov ecx, not_found_msg
	mov edx, 11
	int 80h

	jmp mloop

section .bss
	fbuf: resb 1024 * 1024
	ibuf: resb 1024

	args: resd 3 
	cur_line: resd 1 

section .data
	entry_err_msg: db "Entry error.", 0x0A, 0
	inv_input_msg: db "Invalid user input.", 0x0A, 0
	not_found_msg: db "Not found.", 0x0A, 0
	a_prompt: db " : "

	f_dscrptor: dd 0
	file_name: db "test.txt"
