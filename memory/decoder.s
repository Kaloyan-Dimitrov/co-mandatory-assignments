.data
    block_mask: .quad 0x0000FFFFFFFF0000
    count_mask: .quad 0x000000000000FF00
    char_mask:  .quad 0x00000000000000FF

.text

.include "examples/helloWorld.s"

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
	subq	$32, %rsp

	# your code goes here
	# get the next block address
	movq $block_mask, %rax
	andq %rdi, %rax
	shrq $4, %rax
	
	# get the next block address
	movq $count_mask, %rax
	andq %rdi, %rbx
	shrq $2, %rax

	# get the next block address
	movq $char_mask, %rax
	andq %rdi, %rcx

	# print character n times
	movq -16(%rbp), %rcx
	print_loop:
	    movq -8(%rbp), %rdi
	    call putchar
	loop print_loop

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

