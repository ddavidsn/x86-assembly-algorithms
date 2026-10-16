; for this file, I didnt have the problem with the identation, luckily

section .note.GNU-stack

section .text

extern putc
extern stdout

global my_printf

; first agrument, rdi, will be format
my_printf:
	push rbp
	mov rbp, rsp
	xor rax, rax

	; first we put on stack all values we're about to use
	push rbx
	push r12
	push r13
	push r14
	push r15

	; now, we allign the stack and save the register arguments, from rdi till r9
	sub rsp, 56

	; now, we store all arguments
	mov [rsp], rsi
	; next argument
	mov [rsp + 8], rdx
	; next argument
	mov [rsp + 16], rcx
	; next argument
	mov [rsp + 24], r8
	; next argument
	mov [rsp + 32], r9

	; pointer format
	mov r12, rdi
	; saved register arguments
	mov r13, rsp
	; first argument on stack
	lea r14, [rbp + 16]
	; cnt = 0, number of printed chars
	xor r15, r15
	; cnt_args = 0, how many register arguments were used
	xor ebx, ebx

loop_for_parse:
	; take current character
	mov al, [r12]
	; check if it's \0
	test al, al
	jz done_task

	; now, check if a variable is next
	cmp al, '%'
	je incoming_variable

	; if we arrived till here, it's a basic char
	movzx edi, al
	call print_char
	; next char in format string
	inc r12
	jmp loop_for_parse

incoming_variable:
	; check next char
	inc r12
	mov al, [r12]

	; check case string
	cmp al, 's'
	je pr_argument_is_string

	; check case char
	cmp al, 'c'
	je pr_argument_is_char

	; check case integer
	cmp al, 'l'
	jne unknown_arg

	; also have to check next char, to assure format %lu
	cmp byte [r12 + 1], 'u'
	jne unknown_arg

	; if we arrived till here, we have an integer
	call get_next_argument
	; result is the argument for the function that prints the unsigned var
	mov rdi, rax
	call pr_argument_is_unsigned
	; have to skip another two characters in format string
	add r12, 2
	jmp loop_for_parse

pr_argument_is_string:
	; get argument to print
	call get_next_argument
	; result is the argument for the function that prints a string
	mov rdi, rax
	call print_string
	inc r12
	jmp loop_for_parse

pr_argument_is_char:
	; get argument to print
	call get_next_argument
	; result is the argument for the function that prints a single char
	movzx edi, al
	call print_char
	inc r12
	jmp loop_for_parse

unknown_arg:
	; case % is part of string, we have to print it as it is
	mov edi, '%'
	call print_char
	movzx edi, byte [r12]
	call print_char
	inc r12
	jmp loop_for_parse

done_task:
	; we put what the function will return in rax
	mov rax, r15

	; reallign stack
	add rsp, 56

	; pop used registers from stack back
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx

	leave
	ret

; helper auxiliar functions:

; this function returns the next argument in rax
get_next_argument:
	; if it's from the first 5 arguments, then we take it from stack
	cmp rbx, 5
	jae take_from_stack

	; if not, we take the respective current argument
	mov rax, [r13 + rbx * 8]
	inc rbx
	ret

; takes an argument from stack, using register r14
take_from_stack:
	mov rax, [r14]
	; go to next element on stack
	add r14, 8
	ret

; now, the function ofr printing a single char, means edi = char
print_char:
	; allign stack
	sub rsp, 8

	; for putc(int c, FILE *stream), we need stdout
	mov rsi, [rel stdout]
	call putc

	; reallign
	add rsp, 8
	; another printed char
	inc r15
	ret

; now, function for printing a string, in C similar to rdi = char *
print_string:
	; we are going to use rbx, so save its initial value on stack
	push rbx
	mov rbx, rdi

loop_print_string:
	; take current char from string to be printed
	mov al, [rbx]
	; check if it's end of string
	test al, al
	jz end_of_string

	movzx edi, al
	call print_char
	; next character
	inc rbx
	jmp loop_print_string

end_of_string:
	; pop rbx fromn stack and return
	pop rbx
	ret

; last important function, for printing an unsigned, so edi = unsigned long
pr_argument_is_unsigned:
	; we use rbx, so first save it on stack
	push rbx
	; local buffer for digits of number
	sub rsp, 32

	; in rax, we store the number to be converted
	mov rax, rdi
	; in rbx, end of buffer
	lea rbx, [rsp + 32]

	; check if number is null
	test rax, rax
	jnz loop_convert_integer

	; null number
	mov edi, '0'
	call print_char
	jmp done_integer

; now, we have to convert unsigned long in ASCII characters
loop_convert_integer:
	; in ecx, we use 10 for division, to take a digit at a time
	mov ecx, 10

loop_digit:
	; so that we don't have something left in rdx
	xor edx, edx
	; rdx:rax / rcx
	div rcx
	; convert to ASCII
	add dl, '0'
	; save digit, dec rbx for valid spot
	dec rbx
	mov [rbx], dl
	; check if we have digits left
	test rax, rax
	jnz loop_digit

print_digits:
	; we save in rcx final pos of buffer
	lea rcx, [rsp + 32]
	; check if finished
	cmp rbx, rcx
	jae done_integer

	; we take the current charachter from buffer
	movzx edi, byte [rbx]
	call print_char
	; go to next digit
	inc rbx
	jmp print_digits

done_integer:
	; delete buffer
	add rsp, 32
	; initially, I pushed rbx on stack
	pop rbx
	ret
