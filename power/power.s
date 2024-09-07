.data
prompt: .asciz "Please enter a non-negative base and exponent, separated by whitespace: "
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

    # init loop counter
    movq %rsi, %rcx
pow_loop:
    mulq %rdi
    loop pow_loop

    # epilogue
    addq $16, %rsp
    movq %rbp, %rsp
    popq %rbp

    # return
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
    addq $16, %rsp
    movq %rbp, %rsp
    popq %rbp

    # exit
    movq $0, %rdi
    call exit
