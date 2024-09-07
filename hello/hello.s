.data
hello_text:
    .ascii "Hello world!\n"
    .equ hello_len, . - hello_text

.text
    .global main

main:
    mov $1, %rax # write
    mov $1, %rdi # fd stdout
    mov $hello_text, %rsi # char *buf
    mov $hello_len, %rdx # size_t count
    syscall

    mov $60, %rax # exit
    mov $42, %rdi # exit code
    syscall
