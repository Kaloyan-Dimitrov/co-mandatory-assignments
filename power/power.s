.data
prompt: .asciz "Please enter a positive base and non-negative exponent, separated by whitespace: "
input_format: .asciz "%ld %ld"
output_format: .asciz "The result of %ld ^ %ld is %ld.\n"

.text
    .global main

pow:
    # prologue
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    # initialize result variable
    movq $1, %rax

    # check if base is 0
    cmpq $0, %rdi
    jne base_constraint_check_end
    cmpq $0, %rsi
    jne base_constraint_check_end
	movq $1, %rdi
	call exit

base_constraint_check_end:
    # init loop counter
    movq %rsi, %rcx
pow_loop:
    cmpq $0, %rcx
    jle pow_loop_end
    mulq %rdi
    decq %rcx
    jmp pow_loop
pow_loop_end:

    # epilogue
    movq %rbp, %rsp
    popq %rbp

    ret

main:
    # prologue
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    # print prompt
    movq $prompt, %rdi
    movq $0, %rax
    call printf

    # get user input
    leaq -16(%rbp), %rdx
    leaq -8(%rbp), %rsi
    movq $input_format, %rdi
    movq $0, %rax
    call scanf

    # call pow subroutine
    movq -16(%rbp), %rsi
    movq -8(%rbp), %rdi
    call pow

    # print result of pow
    movq %rax, %rcx
    movq -16(%rbp), %rdx
    movq -8(%rbp), %rsi
    movq $output_format, %rdi
    call printf

    # epilogue
    movq %rbp, %rsp
    popq %rbp

    # exit
    movq $0, %rdi
    call exit
