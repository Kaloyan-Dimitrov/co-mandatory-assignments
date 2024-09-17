.data
    block_mask:	    .quad 0x0000FFFFFFFF0000
    count_mask:     .quad 0x000000000000FF00
    char_mask:      .quad 0x00000000000000FF

.text

.include "final.s"

.global main

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
	subq	$32, %rsp		# reserve 32 bytes, so we keep stack aligned

	# save base address
	movq %rdi, %r9

	decode_while:
	    movq (%rdi), %rdi # load block at address

	    # get the next block offset
	    movq block_mask(%rip), %rax
	    # store block offset in temporary register
	    andq %rdi, %rax
	    # apply offset to get correct value
	    shrq $16, %rax
	    # store on stack so we can use later
	    movq %rax, -16(%rbp)
	    
	    # apply the count mask
	    movq count_mask(%rip), %rcx
	    # store count in loop counter
	    andq %rdi, %rcx
	    # shift right so we get the correct value
	    shrq $8, %rcx

	    # get the character
	    andq char_mask, %rdi

	    # print character n times
	    print_loop:
		# store caller saved registers
		movq %r9, -32(%rbp)
		movq %rdi, -24(%rbp)
		movq %rcx, -8(%rbp)
		call putchar
		# restore caller saved registers
		movq -8(%rbp), %rcx
		movq -24(%rbp), %rdi
		movq -32(%rbp), %r9
	    loop print_loop

	    # check if the index of the next block is 0
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

	movq	$MESSAGE, %rdi	# first parameter: address of the message
	call	decode			# call decode

	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program

