.data
    bg_byte:	    	.quad 0xFF00000000000000
    fg_byte:	    	.quad 0x00FF000000000000
    block_mask:	    	.quad 0x0000FFFFFFFF0000
    count_mask:	    	.quad 0x000000000000FF00
    char_mask:	    	.quad 0x00000000000000FF
    color_format:	.asciz "\x1B[%u;%um%c"
    attr_format:        .asciz "\x1B[%um%c"

.text
.include "helloWorld.s"

.global main

get_attr:
    pushq %rbp
    movq %rsp, %rbp

    cmp $0, %rdi
    je reset
    cmp $37, %rdi
    je stop_blink
    cmp $42, %rdi
    je bold
    cmp $66, %rdi
    je faint
    cmp $105, %rdi
    je conceal
    cmp $153, %rdi
    je reveal
    cmp $182, %rdi
    je blink

reset:
    mov $0, %rax
    jmp end_get_attr
stop_blink:
    mov $25, %rax
    jmp end_get_attr
bold:
    mov $1, %rax
    jmp end_get_attr
faint:
    mov $2, %rax
    jmp end_get_attr
conceal:
    mov $8, %rax
    jmp end_get_attr
reveal:
    mov $28, %rax
    jmp end_get_attr
blink:
    mov $5, %rax
    jmp end_get_attr

end_get_attr:
    movq %rbp, %rsp
    popq %rbp
    ret

# ************************************************************
# Subroutine: print_char			       	     *
# Description: prints a character with a specified fg and bg *
#   or an attribute                                          *
#   - 1 byte char                                            *
#   - 1 byte fg						     *
#   - 1 byte bg						     *
# ************************************************************
print_char:
    # prologue
    pushq %rbp
    movq %rsp, %rbp

    cmpq %rsi, %rdx # cmp fg and bg
    je attribute

    movq %rdi, %rcx # char
    addq $40, %rdx
    addq $30, %rsi
    movq $color_format, %rdi # printf(format, attr, fg, bg, char)
    movq $0, %rax
    call printf
    jmp print_end

    attribute:
    # get correct attribute
    xchgq %rsi, %rdi # swap char and attr
    call get_attr

    movq %rsi, %rdx # char
    movq %rax, %rsi # attr
    movq $attr_format, %rdi # printf(format, attr, fg, bg, char)
    movq $0, %rax
    call printf

    print_end:
    # epilogue
    movq %rbp, %rsp
    popq %rbp

    ret

# ************************************************************
# Subroutine: decode                                         *
# Description: decodes message as defined in Assignment 3    *
#   - 2 byte unknown                                         *
#   - 4 byte index                                           *
#   - 1 byte amount                                          *
#   - 1 byte character                                       *
# Parameters:                                                *
#   first: the address of the message to read                *
#   return: no return value                                  *
# ************************************************************
decode:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer
	subq	$48, %rsp

	# store base address
	movq %rdi, %r9

	decode_while:
	    movq (%rdi), %rdi # load block at address

	    # get the next block offset
	    movq block_mask(%rip), %rax
	    andq %rdi, %rax
	    shrq $16, %rax
	    movq %rax, -16(%rbp)
	    
	    # get the count
	    movq count_mask(%rip), %rcx
	    andq %rdi, %rcx
	    shrq $8, %rcx

	    # get the bg color
	    movq bg_byte(%rip), %rdx
	    andq %rdi, %rdx
	    shrq $56, %rdx

	    # get the fg byte
	    movq fg_byte(%rip), %rsi
	    andq %rdi, %rsi
	    shrq $48, %rsi

	    # get the character
	    andq char_mask, %rdi

	    # print character n times
	    print_loop:
		movq %rcx, -8(%rbp)
		movq %rdi, -24(%rbp)
		movq %rsi, -32(%rbp)
		movq %rdx, -40(%rbp)
		movq %r9, -48(%rbp)
		call print_char
		movq -48(%rbp), %r9
		movq -40(%rbp), %rdx
		movq -32(%rbp), %rsi
		movq -24(%rbp), %rdi
		movq -8(%rbp), %rcx
	    loop print_loop

	    cmpq $0, -16(%rbp)
	    je decode_end

	    # add new address offset
	    movq -16(%rbp), %rax
	    leaq (%r9, %rax, 8), %rdi
	    jmp decode_while

decode_end:
	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret

main:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi		# first parameter: address of the message
	call	decode			# call decode

	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program

