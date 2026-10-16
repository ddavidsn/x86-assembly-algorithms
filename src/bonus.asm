; for this file, I didnt have the problem with the identation, luckily

section .note.GNU-stack

section .data
; 10 is for \n, 0 is for \0
message_case_heavy		db "The number is heavy", 10, 0
; 10 is for \n, 0 is for \0
message_case_not_heavy	db "The number is not heavy", 10, 0
; 10 is for \n, and 0 is for \0
format_flat_mat			db "%d", 10, 0

section .text

extern printf

global ave
global switch_cases
global heavy
global flat_matrix

; for the first bonus function, we have three arguments
; so, rdi is pointer src
; rsi is pointer dest
; and finally, edx is n
ave:
	push rbp
	mov rbp, rsp
	xor rax, rax

	; save n in r8d because the division uses rdx
	mov r8d, edx

	; we will use rcx as i = 0; to iterate through src
	xor rcx, rcx

loop_thr_src:
	; we take the current char
	mov al, byte [rdi + rcx]

	; now, check if we arrived at '\0'
	cmp al, 0
	je ended_src

	; now, we begin calculating the formula
	movzx eax, al
	sub eax, 'A'

	; now, we add n
	add eax, r8d

	; now we have to make eax modula 31
	cdq
	; we use r9d for division
	mov r9d, 31
	idiv r9d

	; we need the remainder
	mov eax, edx

	; add the A
	add eax, 'A'

	; now, put the resulted char in dest
	mov byte [rsi + rcx], al

	; i++
	inc rcx
	jmp loop_thr_src

ended_src:
	; put the '\0' in dest
	mov byte [rsi + rcx], 0

	leave
	ret

; function has two arguments, rdi is src, and rsi is dest, both pointers
switch_cases:
	push rbp
	mov rbp, rsp
	xor rax, rax

	; we use rcx as i = 0
	xor rcx, rcx

loop_all_chars:
	; take current char
	mov al, byte [rdi + rcx]

	; check if we arrived at end of string
	cmp al, 0
	je ended_string

	; check if we have a little char, so al belongs ['a', 'z']
	cmp al, 'a'
	jl check_if_upper
	cmp al, 'z'
	jg check_if_upper

	; if we arrived till here, we have a little char, so we make it big
	sub al, 32
	jmp store_char_dest

check_if_upper:
	; check if al is a big char, so al belongs to ['A', 'Z']
	cmp al, 'A'
	jl store_char_dest
	cmp al, 'Z'
	jg store_char_dest

	; we have a big digit, so transform in a small one
	add al, 32

store_char_dest:
	; save the char in the dest string
	mov byte [rsi + rcx], al
	; go to next char
	inc rcx
	jmp loop_all_chars

ended_string:
	; last char of dest is \0
	mov byte [rsi + rcx], 0

	leave
	ret

; only argument of function, rdi, is number
heavy:
	push rbp
	mov rbp, rsp
	xor rax, rax

	; 1st condition : MSB is set, chosen number is mask for bit 31
	test edi, 0x80000000
	jz nr_isnt_heavy

	; 2nd condition; we have to concatenate byte 3 and 4, this order
	; first, byte 3, so bits 23->16
	mov eax, edi
	; from pos 16
	shr eax, 16
	; 0xFF is mask for 1 byte
	and eax, 0xFF

	; now, byte 4, so bits 31->24
	mov ecx, edi
	; from pos 24
	shr ecx, 24
	; 0xFF is mask for 1 byte
	and ecx, 0xFF

	; now we concatenate the two
	shl eax, 8
	or eax, ecx

	; check if it's bigger than 255
	cmp eax, 255
	jbe nr_isnt_heavy

	; if we arrived till here, number is heavy, print heavy message
	lea rdi, [rel message_case_heavy]
	xor eax, eax
	call printf
	jmp done_heavy_f

nr_isnt_heavy:
	; print the not heavy message
	lea rdi, [rel message_case_not_heavy]
	xor eax, eax
	call printf

done_heavy_f:
	leave
	ret

; function has two arguments, rdi is pointer mat, and esi is n
flat_matrix:
	push rbp
	mov rbp, rsp
	xor rax, rax

	; put on stack values that we'll use
	push rbx
	push r12
	push r13
	push r14
	push r15

	; in r12, we will store the mat, and in r13, n
	mov r12, rdi
	mov r13d, esi

	; edge case, n <= 0
	cmp r13d, 0
	jle ended_flat_mat

	; we will use r14d = j, for loop for all columns
	xor r14d, r14d

loop_for_columns:
	; if j is >= n, we ended the loop
	cmp r14d, r13d
	jge ended_flat_mat

	; in rbx, we store the max, so initially the first element
	; of the matrix from the column j
	movsxd rax, r14d
	; 4 beacuse of int
	mov ebx, dword [r12 + rax * 4]

	; now, we use r15d for i to loop through entire column, starts from second
	; element, so initially 1
	mov r15d, 1

loop_for_rows:
	; check if we ended the current column
	cmp r15d, r13d
	jge print_max_col

	; now, we calculate the current index, so index = i * n + j
	mov eax, r15d
	imul eax, r13d
	add eax, r14d

	; transform eax into rax, for safety
	cdqe
	; int => 4
	mov edx, dword [r12 + rax * 4]

	; check if we have to update the max
	cmp edx, ebx
	jle skip_update_max

	; if we arrived till here, change max
	mov ebx, edx

skip_update_max:
	; i++
	inc r15d
	jmp loop_for_rows

print_max_col:
	; we have to print a new max on each line
	; prepare arguments for printf
	lea rdi, [rel format_flat_mat]
	mov esi, ebx
	xor eax, eax
	call printf

	; j++
	inc r14d
	jmp loop_for_columns

ended_flat_mat:
	; retrieve from stack
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx

	leave
	ret
