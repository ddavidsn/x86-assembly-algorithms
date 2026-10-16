
section .note.GNU-stack

section .rodata
; 0 for \0
format_input		db "%63s", 0
; 10 is for \n, 0 for \0
format_output		db "%ld", 10, 0

section .text

extern scanf
extern printf
extern atol

global reverse_polish_notation

; top will tell us the number of values in the stack
%define OFFSET_TOP 8
; offset for the buffer, were we'll store the read value
; 64 + 8 => 72
%define OFFSET_BUFFER 72
; 10000 * 8 + 72 + 8 => 80080, the vector used as stack RPN
%define OFFSET_STACK 80080

reverse_polish_notation:
push rbp
mov rbp, rsp
xor rax, rax

; preparing stack
sub rsp, OFFSET_STACK

; top will store the number of values that are in the stack presently
; so initially zero
mov qword [rbp - OFFSET_TOP], 0

loop_reading_tokens:
; we read a value or an operator
; prepare arguments for scanf
lea rdi, [rel format_input]
; we store the value in buffer
lea rsi, [rbp - OFFSET_BUFFER]
xor eax, eax
call scanf

; check if we have read something useful or EOF, scanf should return 1
cmp eax, 1
jne print_polish_result

; if it's a one character token, it might pe an operator
mov al, byte [rbp - OFFSET_BUFFER]
; check if next character is null
cmp byte [rbp - OFFSET_BUFFER + 1], 0
jne push_number

; if we arrived till here, may be operator
cmp al, '+'
je operation_add
cmp al, '-'
je operation_sub
cmp al, '*'
je operation_mul
cmp al, '/'
je operation_div

push_number:
; we have to convert the string to a 64 bit signed integer
lea rdi, [rbp - OFFSET_BUFFER]
call atol

; pos for number in stack
mov rcx, [rbp - OFFSET_TOP]
; put it in stack
mov qword [rbp - OFFSET_STACK + rcx * 8], rax
; len of stack ++
inc rcx
mov qword [rbp - OFFSET_TOP], rcx
jmp loop_reading_tokens

operation_add:
; we have to add the last two values from stack
; in rcx, we store the len of stack, for pos
mov rcx, qword [rbp - OFFSET_TOP]
dec rcx
; we will use r8 for one number and rax for the other one
mov r8, qword [rbp - OFFSET_STACK + rcx * 8]
; now other number
dec rcx
; calculate the pos of second number
mov rax, qword [rbp - OFFSET_STACK + rcx * 8]
add rax, r8
jmp push_result_of_operation

operation_sub:
; we have to sub the last two values from stack
; in rcx, we store the len of stack, for pos
mov rcx, qword [rbp - OFFSET_TOP]
dec rcx
; we will use r8 for one number and rax for the other one
mov r8, qword [rbp - OFFSET_STACK + rcx * 8]
; now other number
dec rcx
; calculate the pos of second number
mov rax, qword [rbp - OFFSET_STACK + rcx * 8]
; remember, A - B!
sub rax, r8
jmp push_result_of_operation

operation_mul:
; we have to multiply the last two values from stack
; in rcx, we store the len of stack, for pos
mov rcx, qword [rbp - OFFSET_TOP]
dec rcx
; we will use r8 for one number and rax for the other one
mov r8, qword [rbp - OFFSET_STACK + rcx * 8]
; now other number
dec rcx
; calculate the pos of second number
mov rax, qword [rbp - OFFSET_STACK + rcx * 8]
imul rax, r8
jmp push_result_of_operation

operation_div:
; we have to divide the last two values from stack
; in rcx, we store the len of stack, for pos
mov rcx, qword [rbp - OFFSET_TOP]
dec rcx
; we will use r8 for one number and rax for the other one
mov r8, qword [rbp - OFFSET_STACK + rcx * 8]
; now other number
dec rcx
; calculate the pos of second number
mov rax, qword [rbp - OFFSET_STACK + rcx * 8]
; remember, A / B!; extension of rax in rdx
cqo
idiv r8
jmp push_result_of_operation

push_result_of_operation:
; we always store the result in rax
; we have to replace the last two values with rax only
mov qword [rbp - OFFSET_STACK + rcx * 8], rax
; update len, so len ++
inc rcx
mov qword [rbp - OFFSET_TOP], rcx
jmp loop_reading_tokens

print_polish_result:
; the final result is the last element on stack
mov rcx, [rbp - OFFSET_TOP]
dec rcx
; we use rcx to find out the index of final result; qword => 8 bytes
mov rsi, [rbp - OFFSET_STACK + rcx * 8]
lea rdi, [rel format_output]
xor eax, eax
call printf

leave
ret
