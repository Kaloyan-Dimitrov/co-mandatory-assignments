.data
    format_string: .asciz "My name is %s. I think I’ll get a %u for my exam. What does %r do? And %%?\n"
    name_string: .asciz "Piet"
    exam_result: .quad 10

.text

.global main

# int len(char *string)
# %rdi - string (null-terminated)
len:
    # prologue
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rcx
    len_loop:
	movb (%rdi, %rcx, 1), %dl
	cmpb $0, %dl
	je len_loop_end
	incq %rcx
	jmp len_loop
    len_loop_end:

    # store result into %rax
    movq %rcx, %rax

    # epilogue
    movq %rbp, %rsp
    popq %rbp

    ret

# char* print_until_specifier(char *string)
# %rdi - string (null-terminated)
# returns pointer to last printed character
print_until_specifier:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rcx
    loop_until_specifier:
	movq (%rdi, %rcx, 1), %rdx
	cmpb $37, %dl
	je loop_until_specifier_end
	cmpb $0, %dl
	je loop_until_specifier_end
	incq %rcx
	jmp loop_until_specifier
    loop_until_specifier_end:

    movq %rcx, %rdx # len
    movq %rdi, %rsi # buf
    movq $1, %rdi # stdout
    movq $1, %rax # write
    syscall

    # return pointer to last printed character
    movq (%rdi, %rcx, 1), %rax

    movq %rbp, %rsp
    popq %rbp

    ret

# void print_string(char *string)
# %rdi - string (null-terminated)
print_string:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    movq %rdi, -8(%rbp)
    call len

    movq %rax, %rdx # len
    movq -8(%rbp), %rsi # string
    movq $1, %rdi # stdout
    movq $1, %rax # write
    syscall
    
    movq %rbp, %rsp
    popq %rbp

    ret

# handle specifier

# printf(char *format_string, ...)
# %rdi - format_string
# %rsi - 1st argument
# %rdx - 2nd argument
# %rcx - 3rd argument
# %r8 - 4th argument
# %r9 - 5th argument
# printf with %d %u %s and %% specifiers
my_printf:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    
    # store string to stack
    movq %rdi, -8(%rbp)

    # store arguments processed
    movq $0, %rbx
    print_loop:
	movq -8(%rbp), %rdi
	call print_until_specifier
	movq %rax, %rdi
	call handle_specifier
	movq $1, %r10
	cmpb $0, (%rdi, %r10, 1)
	je print_loop_end
	jmp print_loop
    print_loop_end:

    # exit syscall
    movq $0, %rdi
    movq $60, %rax
    syscall

    movq %rbp, %rsp
    popq %rbp

    ret

main:
    pushq %rbp
    movq %rsp, %rbp
    
    # call our printf
    movq exam_result, %rdx
    movq $name_string, %rsi
    movq $format_string, %rdi
    call my_printf

    # exit syscall
    movq $0, %rdi
    movq $60, %rax
    syscall

    movq %rbp, %rsp
    popq %rbp

    ret
