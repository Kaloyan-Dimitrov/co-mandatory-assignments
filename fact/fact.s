.data
number_format: .asciz "%ld"
number_prompt: .asciz "Enter a non-negative number: "
output_format: .asciz "%ld! = %ld\n"

.text

    .global main

fact:
    # prologue
    push %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    # store n to stack
    movq %rdi, -8(%rbp)

    # check if we are at the base case
    cmpq $0, -8(%rbp)
    je base_case # n == 1
    jmp recursive_fact # n > 1

base_case:
    movq $1, %rax
    jmp fact_end

recursive_fact:
    decq %rdi # new_n = n - 1
    call fact # call fact(new_n)
    mulq -8(%rbp) # fact(new_n) * n

fact_end:
    # epilogue
    addq $16, %rsp
    movq %rbp, %rsp
    popq %rbp

    # return
    ret

main:
    # prologue
    push %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    # initialize input variable with -1
    movq $-1, -8(%rbp)

input_loop:
    movq $number_prompt, %rdi
    movq $1, %rax
    call printf

    leaq -8(%rbp), %rsi
    movq $number_format, %rdi
    movq $1, %rax
    call scanf

    cmpq $0, -8(%rbp)
    jl input_loop

    # call fact(n)
    mov -8(%rbp), %rdi
    call fact

    # store result on stack
    mov %rax, -16(%rbp)

    # print result
    mov -16(%rbp), %rdx
    mov -8(%rbp), %rsi
    mov $output_format, %rdi
    mov $0, %rax
    call printf

    # epilogue
    addq $16, %rsp
    movq %rbp, %rsp
    popq %rbp

    # exit
    movq $0, %rax
    call exit
