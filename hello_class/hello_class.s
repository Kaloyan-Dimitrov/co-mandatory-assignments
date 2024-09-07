.data
    prompt: .asciz "%ld"
    class: .asciz "Number: %ld\n"

.text
.global main

main:
    push %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    leaq -8(%rbp), %rsi
    movq $prompt, %rdi
    movq $0, %rax
    call scanf

    movq $0, %rax
    movq $class, %rdi
    movq -8(%rbp), %rsi
    call printf

    addq $16, %rsp
    movq %rbp, %rsp
    popq %rbp

    movq $0, %rdi
    call exit
