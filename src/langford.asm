
section .note.GNU-stack

section .text

extern malloc
extern calloc
extern realloc
extern free

global check_langford
global generate_langford_sequences

; we will use, for the second subtask, like a C structure
; with all necessary data
; that means n, len, the sequence, the array of results, the count, the cap
; and the used array
; first, offset for n, order of langford seq
%define STR_OFF_N 		0
; next, for the len of the langford sequence, that means 2 * n
%define STR_OFF_LEN		4
; next, a pointer to the current sequence we're completing
%define STR_OFF_SEQ		8
; then, a pointer to the result array
%define STR_OFF_RES		16
; next, number representing how many valid sequences have been found
%define STR_OFF_COUNT	24
; also, capacity of the result array
%define STR_OFF_CAPAC	28
; lastly, pointer for used array for generating correct sequences,
; knowing if value is alr used or not
%define STR_OFF_USED	32

; two arguments, first is rdi = pointer seq, second one is rsi = len
check_langford:
push rbp
mov rbp, rsp
xor rax, rax

; first, the len must be positive and even
cmp esi, 0
jle not_langf_seq
; now even
test esi, 1
jnz not_langf_seq

; now, we store the len in r8d
mov r8d, esi
; and make len / 2, to know who the n is (1,1, ..., n, n)
shr r8d, 1
; in r9d, we'll have an i = 1, that will take values to check from 1 to r8d
mov r9d, 1

loop_check_i:
; if we have checked for all numbers till n/r9d, we found a good seq
cmp r9d, r8d
jg pos_langf_seq

; in r10d, we count how many times i appears in the seq
xor r10d, r10d
; r11d we'll use for the first pos
mov r11d, -1
; ecx will be a j, to iterate through seq
xor ecx, ecx

scanning_sequence:
; check if we finished sequence
cmp ecx, esi
jge finished_scan

; we store the current number from seq
mov eax, dword [rdi + rcx * 4]
; check if seq[j] == i
cmp eax, r9d
jne continue_scanning

; if we arrived here, seq[j] = i, we found first or maybe second
cmp r10d, 0
jne second_apparition

; first apparition, so save pos
mov r11d, ecx
inc r10d
jmp continue_scanning

second_apparition:
; check if number of apparition is 1
cmp r10d, 1
jne not_langf_seq

; now, we have to check distance between positions
mov edx, ecx
sub edx, r11d

; in eax, we provide current (i + 1), for checking
mov eax, r9d
inc eax

; checking:
cmp eax, edx
jne not_langf_seq

inc r10d

continue_scanning:
; j++
inc ecx
jmp scanning_sequence

finished_scan:
; check if last i appeared exactly two times
cmp r10d, 2
jne not_langf_seq

; i++
inc r9d
jmp loop_check_i

pos_langf_seq:
; the sequence is langford, so the function returns 1
mov eax, 1

leave
ret

not_langf_seq:
; in this case, the function returns 0 so
xor eax, eax

leave
ret

; only one argument, rdi, is the pointer for custom structure
save_langf_seq:
push rbp
mov rbp, rsp

; put needed registers on stack
push rbx
push r12
push r13
push r14
push r15

; allign stack correctly
sub rsp, 8

; in r12, we store the structure
mov r12, rdi

; check if the capacity is still ok or realloc is needed
mov eax, dword [r12 + STR_OFF_COUNT]
cmp eax, dword [r12 + STR_OFF_CAPAC]
jl capac_still_good

; we need to realloc capacity
; first, save current capacity
mov ebx, dword [r12 + STR_OFF_CAPAC]
; then, double it
shl ebx, 1

; prepare arguments for realloc
mov rdi, qword [r12 + STR_OFF_RES]
movsxd rsi, ebx
; now, * 8, because of sizeof()
shl rsi, 3
call realloc

; safety precautions
test rax, rax
jz done_saving

; update structure
mov qword [r12 + STR_OFF_RES], rax
mov dword [r12 + STR_OFF_CAPAC], ebx

capac_still_good:
; if we arrived here, capacity is surely ok
; we need to malloc another sequence
movsxd rdi, dword [r12 + STR_OFF_LEN]
; * 4 because of sizeof(int)
shl rdi, 2
call malloc

; safety precaution
test rax, rax
jz done_saving

; we store the new obtained seq in r13
mov r13, rax
; in r14, we put the sequence to be copied
mov r14, qword [r12 + STR_OFF_SEQ]
; we use ebx as i = 0 for copy loop
xor ebx, ebx
; lastly, we need the len to compare ebx
mov r15d, dword [r12 + STR_OFF_LEN]

loop_copy_seq:
; check if we finished seq
cmp ebx, r15d
jge store_sequence

; take current number from sequence
mov eax, dword [r14 + rbx * 4]
; and copy it
mov dword [r13 + rbx * 4], eax

; i++
inc ebx
jmp loop_copy_seq

store_sequence:
; we need to store the copied seq in our custom structure
mov rax, qword [r12 + STR_OFF_RES]
mov ebx, dword [r12 + STR_OFF_COUNT]

; put the new sequence on last pos in res array
mov qword [rax + rbx * 8], r13

; count of seq ++
inc ebx
mov dword [r12 + STR_OFF_COUNT], ebx

done_saving:
; reallign
add rsp, 8

; retrieve from stack
pop r15
pop r14
pop r13
pop r12
pop rbx

leave
ret

; one argument, rdi, pointer entire strcuture containing all info
generate_seq_for_res:
push rbp
mov rbp, rsp

; save needed variables on stack
push rbx
push r12
push r13
push r14
push r15

; + allign stack
sub rsp, 8

; in r12, we'll store whole rdi
mov r12, rdi
; in r13, we'll store the current seq
mov r13, qword [r12 + STR_OFF_SEQ]
; and in r14d, we'll store the len
mov r14d, dword [r12 + STR_OFF_LEN]

; we will use r15d as pos = 0
xor r15d, r15d

find_empty_spot:
; check if pos is still < len
cmp r15d, r14d
jge completed_sequence

; check if current element in sequence is still 0
cmp dword [r13 + r15 * 4], 0
je trying_values

; pos++
inc r15d
jmp find_empty_spot

completed_sequence:
; we want to prepare for saving the sequence
mov rdi, r12
call save_langf_seq
jmp done_generating

trying_values:
; initial value 1
mov ebx, 1

loop_for_value:
; check if value is bigger than n
cmp ebx, dword [r12 + STR_OFF_N]
jg done_generating

; if this value has been used, skip
mov rax, qword [r12 + STR_OFF_USED]
; check if used
cmp dword [rax + rbx * 4], 0
jne next_value

; store the first pos
mov eax, r15d
; find the next pos for the value, so ebx + 1
add eax, ebx
inc eax

; check if it's < than len
cmp eax, r14d
jge next_value

movsxd rcx, eax

; check if that spot is free
cmp dword [r13 + rcx * 4], 0
jne next_value

; if we arrived till here, we can put both values in the sequence
mov dword [r13 + r15 * 4], ebx
; and on second pos
mov dword [r13 + rcx * 4], ebx

; mark value as used
mov rax, qword [r12 + STR_OFF_USED]
; used[value] => 1
mov dword [rax + rbx * 4], 1

; save the second pos on the stack
mov qword [rsp], rcx

; prepare for recursive call
mov rdi, r12
; backtracking step
call generate_seq_for_res

; restore second pos from stack
mov rcx, qword [rsp]

; backtrackin undo step
mov dword [r13 + r15 * 4], 0
; also reset
mov dword [r13 + rcx * 4], 0

; mark value as unused again
mov rax, qword [r12 + STR_OFF_USED]
; used[value] => 0
mov dword [rax + rbx * 4], 0

next_value:
; value++
inc ebx
jmp loop_for_value

done_generating:
; reallign stack
add rsp, 8

; retrieve from stack
pop r15
pop r14
pop r13
pop r12
pop rbx

leave
ret

; two arguments for this function, first, rdi is n
; rsi is pointer to seq_num, the number of langford sequences
generate_langford_sequences:
push rbp
mov rbp, rsp
xor rax, rax

; first, we reserve space on the stack for the custom structure
sub rsp, 64

; now, we save the rsi on the stack, because we need rsi for other funcs
mov qword [rbp - 64], rsi

; safety precaution, check if the pointer is NULL
test rsi, rsi
jz func_returns_null

; initially, 0 sequences
mov dword [rsi], 0

; langford sequence exists only if n is M4 or M4 + 3
; number of odd values from 1 to n must be even
test edi, edi
; if negative or 0, returns null
jle func_returns_null

; we don't want to destroy original n
mov eax, edi
; we keep only last two bits of n, to know the rest for n / 4
and eax, 3

; if rest is 0
cmp eax, 0
je possible_to_make

; if rest is 3
cmp eax, 3
jne func_returns_null

possible_to_make:
; now, we begin using our customized structure, for which we declared offset
mov dword [rbp - 56 + STR_OFF_N], edi

; now, we want to know the len, so:
mov eax, edi
; len = n * 2
shl eax, 1
; save len
mov dword [rbp - 56 + STR_OFF_LEN], eax

; calloc for the current sequence, calloc(2 * n, sizeof(int))
movsxd rdi, eax
; sizeof(int) = 4
mov esi, 4
call calloc

; safety precaution, like DIE(rax == NULL)
test rax, rax
jz func_returns_null

; save the current sequence
mov qword [rbp - 56 + STR_OFF_SEQ], rax

; calloc for used array, calloc(n + 1, sizeof(int))
mov edi, dword [rbp - 56 + STR_OFF_N]
inc edi
; sizeof(int) = 4
mov esi, 4
call calloc

; safety precaution
test rax, rax
jz free_seq_then_null

; saving the used array
mov qword [rbp - 56 + STR_OFF_USED], rax

; now, we want to generate the result array,
; with initial capacity for 4 sequences
mov edi, 32
call malloc

; safety precaution as always
test rax, rax
jz free_seq_n_used_then_null

; store the result array
mov qword [rbp - 56 + STR_OFF_RES], rax
; count is initially zero
mov dword [rbp - 56 + STR_OFF_COUNT], 0
; and current capacity is, as mentioned previously, 4
mov dword [rbp - 56 + STR_OFF_CAPAC], 4

; prepare argument for the helper function, which does all the backtracking
lea rdi, [rbp - 56]
call generate_seq_for_res

; we have to free the dynamical memory for the seq
mov rdi, qword [rbp - 56 + STR_OFF_SEQ]
call free

; also free the used array
mov rdi, qword [rbp - 56 + STR_OFF_USED]
call free

; now, test how many sequences we obtained
mov eax, dword [rbp - 56 + STR_OFF_COUNT]
test eax, eax
jz free_res_then_null

; in rdx, we retrieve the pointer to seq_num
mov rdx, qword [rbp - 64]
; update the seq_num with the obtained seq count
mov dword [rdx], eax

; the function returns int **, so
mov rax, qword [rbp - 56 + STR_OFF_RES]

leave
ret

free_res_then_null:
; we already freed seq, so we just have to free res
mov rdi, qword [rbp - 56 + STR_OFF_RES]
call free
jmp func_returns_null

free_seq_n_used_then_null:
; free used array
mov rdi, qword [rbp - 56 + STR_OFF_USED]
call free

free_seq_then_null:
; fucntion returns null, but first we must free seq
mov rdi, qword [rbp - 56 + STR_OFF_SEQ]
call free

func_returns_null:
; we return NULL
xor eax, eax

leave
ret
