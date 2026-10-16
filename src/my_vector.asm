
section .note.GNU-stack

section .data
; 10 is for \n and 0 for \0
format_err_len		db "Error: len <= %d", 10, 0
; analogue
format_empty		db "The vector is empty", 10, 0

; 0 for \0
format_start		db "v -> {(", 0
; 0 for \0
format_element		db "[%d]", 0
; 0 for \0
format_empty_elem	db "[]", 0
; 0 for \0 and 10 for \n
format_end			db "), %d, %d}", 10, 0

section .text

extern malloc
extern realloc
extern free
extern printf

global new_vector
global set_element
global get_element
global push_element
global pop_element
global print_vector
global free_vector

; offset for arr in vec structure
%define OFFSET_ARR 0
; offset for len in vec structure
%define OFFSET_LEN 8
; offset for capac in vec structure
%define OFFSET_CAPAC 12
; total size of vec structure
%define STRUC_VEC_SIZE 16

;	struct vector {
;		int *arr;
;		int len;
;		int cap;
;	}

; in rdi, the first and only argment of function, so capacity
new_vector:
push rbp
mov rbp, rsp
xor rax, rax

; save this values on the stack, don't loose initial value
push rbx
push r12

; we save the capacity in r12d, d because of int values
mov r12d, edi

; check if the capacity is valid, must be >= than 1
cmp r12d, 1
jge valid_capac

; if we arrived till here, not valid capacity, we put the bare minimum
mov r12d, 1

valid_capac:
; we store the size of the vector structure
mov edi, STRUC_VEC_SIZE

; equivalent to malloc(sizeof(struct vector)) in C, saves in rax
call malloc

; test if rax has a valid address
cmp rax, 0
je fail_new_vector

; now, we store in rbx the address of the created new vector
mov rbx, rax

; now, we calculate in rax the real capacity, so *4 because of int
mov eax, r12d
; int => 4
imul eax, 4
mov edi, eax
; so now, we have a malloc(capacity * sizeof(int)) in C
call malloc

; we test again
cmp rax, 0
je failed_array

; in rbx, with offset 0, we store the address of the created array
mov [rbx + OFFSET_ARR], rax
; initial length of new vector is 0
mov dword [rbx + OFFSET_LEN], 0
; initial capacity is the one given by the argument
mov [rbx + OFFSET_CAPAC], r12d

; the function returns in rax, so we store there
mov rax, rbx
jmp end_of_new_vector

failed_array:
; this is the case whn the second malloc, so the one for the arr, failed
; so, we have to free the first malloc

mov rdi, rbx
call free
xor rax, rax
jmp end_of_new_vector

fail_new_vector:
; case when the first malloc, so that of the vector structure, failed
xor rax, rax

end_of_new_vector:
pop r12
pop rbx

leave
ret

; first argument, rdi, is pointer vec
; second argument, esi, is elem
; third argument, edx, is pos
set_element:
push rbp
mov rbp, rsp
xor rax, rax

push rbx
push r12

; in rbx, we'll store the vec
mov rbx, rdi
; in r12d, we'll store the pos
mov r12d, edx

; case, vec is null
cmp rbx, 0
je error_set_elem

; now we check is pos is valid, first seeing if it's negative
cmp r12d, 0
jl error_set_elem

; now, we check is it's bigger than the length of the array
mov eax, [rbx + OFFSET_LEN]
cmp r12d, eax
jge error_set_elem

; if we arrived till here, valid pos
mov rax, [rbx + OFFSET_ARR]
; now, we get the elem on position pos and set the elem
mov [rax + r12 * 4], esi

; if successful, the function returns the pos
mov eax, r12d
jmp end_set_elem

error_set_elem:
; we print the error message; for printf
lea rdi, [rel format_err_len]
mov esi, r12d
xor eax, eax
call printf

; in this case, function returns -1
mov eax, -1

end_set_elem:
pop r12
pop rbx

leave
ret

; first argument, rdi, is pointer vec
; second argument, esi, is pos
get_element:
push rbp
mov rbp, rsp
xor rax, rax

push rbx
push r12

; in rbx, we'll store the vec
mov rbx, rdi
; in r12d, we'll store the pos
mov r12d, esi

; check if vec is null
cmp rbx, 0
je error_get_elem

; check if pos/r12d is < 0
cmp r12d, 0
jl error_get_elem

; now, check is pos is >= len of array
mov eax, [rbx + OFFSET_LEN]
cmp r12d, eax
jge error_get_elem

; first, we store in rax the start of the arr
mov rax, [rbx + OFFSET_ARR]
; now, we get the pos-th element
mov eax, [rax + r12 * 4]
jmp end_get_elem

error_get_elem:
; we have an error, so we print the error message
lea rdi, [rel format_err_len]
mov esi, r12d
xor eax, eax
call printf

; the function returns -1
mov eax, -1

end_get_elem:
pop r12
pop rbx

leave
ret

; first argument, rdi, is pointer vec
; second argument, esi, is value of new elem to be pushed
push_element:
push rbp
mov rbp, rsp
xor rax, rax

push rbx
push r12
push r13

; for correct allign of stack
sub rsp, 8

; in rbx, we'll store the vec
mov rbx, rdi

; safety check vec is null
cmp rbx, 0
je failed_push

; in r12d, we'll store the value of the new element
mov r12d, esi

; now, in r13d, we store the pos were we have to insert
; with other words, len
mov eax, [rbx + OFFSET_LEN]
mov r13d, eax

; we also have to store the capacity, to know if realloc is needed
mov ecx, [rbx + OFFSET_CAPAC]
cmp eax, ecx
; if eax < ecx, so len < capac, realloc isn't needed
jl insert_elem

; if we arrived till here, realloc is needed, so we need to
; double the current capacity
shl ecx, 1
; save the new capac on stack
push rcx

; now, for realloc, first argument is vec->arr, and second is capac * 4(int)
mov rdi, [rbx + OFFSET_ARR]
mov eax, ecx
; 4 = sizeof(int)
imul eax, 4
mov esi, eax
call realloc

pop rcx

; check if realloc succeded
cmp rax, 0
je failed_push

; if not failed, save new array
mov [rbx + OFFSET_ARR], rax
; save new capacity
mov [rbx + OFFSET_CAPAC], ecx

insert_elem:
; we save the array in rax
mov rax, [rbx + OFFSET_ARR]
; now, we put the value stored in r12d, on pos r13d
mov [rax + r13 * 4], r12d

; len++
inc dword [rbx + OFFSET_LEN]

; function returns the pos where the elem was inserted
mov eax, r13d
jmp end_of_push_elem

failed_push:
; failed return is -1
mov eax, -1

end_of_push_elem:
; reallign of stack
add rsp, 8

pop r13
pop r12
pop rbx

leave
ret

; first and only argument is rdi = pointer vec
pop_element:
push rbp
mov rbp, rsp
xor rax, rax

push rbx
push r12
push r13

; stack allign
sub rsp, 8

; in rbx, we'll store the vec
mov rbx, rdi

; safety precaution
cmp rbx, 0
je pop_empty_vec

; in eax, we'll store the current len
mov eax, [rbx + OFFSET_LEN]
; check if len == 0
cmp eax, 0
je pop_empty_vec

; we decrease the current len
dec eax
; save new len
mov [rbx + OFFSET_LEN], eax
; now, in r13d, we'll store the current new len
mov r13d, eax

; in r12d, we'll store the value of the elem to be popped
mov rax, [rbx + OFFSET_ARR]
; with rax intermediate, we take the value of elem correctly
mov r12d, [rax + r13 * 4]

; now, we have to check if we can halve the current arr
; so, we check if capac is > 1 and new len <= capac / 2
; first, we save capac
mov ecx, [rbx + OFFSET_CAPAC]
; first check capac > 1
cmp ecx, 1
jle pop_return

mov eax, ecx
; we halve the current capac
shr eax, 1

; check if new_len <= capac / 2
cmp r13d, eax
jg pop_return

; if we arrived till here, we can halve the arr
; we store the new capac in ecx
mov ecx, eax
; save ecx on stack
push rcx

; prepare arguments for realloc
mov rdi, [rbx + OFFSET_ARR]
mov eax, ecx
; capac * 4 from int
imul eax, 4
mov esi, eax
call realloc

pop rcx

; test if success
cmp rax, 0
je pop_return

; save new arr
mov [rbx + OFFSET_ARR], rax
; save new capac
mov [rbx + OFFSET_CAPAC], ecx

pop_return:
; we return the popped value
mov eax, r12d
jmp end_of_pop_elem

pop_empty_vec:
; case vector is empty, print specified message
lea rdi, [rel format_empty]
xor eax, eax
call printf

; return value -1
mov eax, -1

end_of_pop_elem:
; stack reallign
add rsp, 8

pop r13
pop r12
pop rbx

leave
ret

; first and only argument is pointer vec, stored in rdi
print_vector:
push rbp
mov rbp, rsp
xor rax, rax

; put on stack values we're about to use
push rbx
push r12
push r13
push r14

; in rbx, we store the vec
mov rbx, rdi

; check if vec is null
cmp rbx, 0
je case_null_vec

; first, we have to print the begin format
lea rdi, [rel format_start]
xor eax, eax
call printf

; now, we need an i to iterate through array, the len and the capac
; i = 0
xor r12d, r12d
; r13d = len
mov r13d, [rbx + OFFSET_LEN]
; r14d = capac
mov r14d, [rbx + OFFSET_CAPAC]

loop_for_print:
; check if we printed all elements, comparing with capac
cmp r12d, r14d
jge end_of_print_vec

; now check if i < len, to know if empty elem or not
cmp r12d, r13d
jl print_not_empty_elem

; we have to print empty element
lea rdi, [rel format_empty_elem]
xor eax, eax
call printf
jmp increase_i

print_not_empty_elem:
; we print the real elem of arr
lea rdi, [rel format_element]
; we take the current element
mov rax, [rbx + OFFSET_ARR]
; current pos is r12 * sizeof(int)
mov esi, [rax + r12 * 4]
xor eax, eax
call printf

increase_i:
; i++
inc r12d
jmp loop_for_print

end_of_print_vec:
; now, we have to print the end stucture
; including len and capac
lea rdi, [rel format_end]
mov esi, [rbx + OFFSET_LEN]
mov edx, [rbx + OFFSET_CAPAC]
xor eax, eax
call printf

case_null_vec:
; now pop from stack
pop r14
pop r13
pop r12
pop rbx

leave
ret

; first agrument, rdi, is &vec
free_vector:
push rbp
mov rbp, rsp
xor rax, rax

; put on stack elem we are about to use
push rbx
push r12

; store &vec in rbx
mov rbx, rdi

; check if &vec is null
cmp rbx, 0
je end_of_free

; now, we store vec without & in rdi
mov r12, [rbx]
; check if vec is null
cmp r12, 0
je end_of_free

; we have to free first the arr of vec, then the vec

; now, we free the vec->arr
mov rdi, [r12 + OFFSET_ARR]
call free

mov rdi, r12
call free

; we make the pointer NULL
mov qword [rbx], 0

end_of_free:
; pop from stack
pop r12
pop rbx

leave
ret
