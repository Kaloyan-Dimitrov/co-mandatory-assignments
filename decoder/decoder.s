.data
    block_mask: .quad 0x0000FFFFFFFF0000
    count_mask: .quad 0x000000000000FF00
    char_mask:  .quad 0x00000000000000FF

.text

.include "examples/final.s"

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
	subq	$16, %rsp

	# your code goes here
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

	# get the character
	andq char_mask, %rdi

	# print character n times
	print_loop:
	    movq %rcx, -8(%rbp)
	    call putchar
	    movq -8(%rbp), %rcx
	loop print_loop

	cmpq $0, -16(%rbp)
	je decode_end

	# add new address offset
	movq -16(%rbp), %rax
	leaq MESSAGE(, %rax, 8), %rdi
	call decode

decode_end:
	# epilogue
	addq	$32, %rsp
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

