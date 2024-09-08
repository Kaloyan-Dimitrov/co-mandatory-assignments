.data
string: .asciz "%c"

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

/**

		/**
		* Subroutine: decode 
		* Description: decodes message as defined in Assignment 3
		*	 - 2 byte unknown   
		*	 - 4 byte index     
		*	 - 1 byte amount    
		*  - 1 byte character 
		*
		* Parameters:
		*
		* 	first: the address of the message to read
		*
		* Return value: no return value.
		/

		void decode(int address) {
			int firstQuad = (address);

		}

*/

decode:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq (%rdi), %r15 # copy the first quad from the message into r15 (we will not modify %r15, so that we can use it as a reference)
	movq %r15, %rbx # copy %r15 again in %rbx so that we can work with it
	shr $8, %rbx # shift by 8 bites, to get the second to last byte, which stores n (the number of repetitions)
	movq $0, %r13 # clear %r13, so that we can use it as a counter
	movb %bl, %r13b # copy the last byte of %rbx (which is currently n) into the last byte of %r13b
	movq %r15, %rbx # return %rbx to the original quadword (%r15)
	
	while:
		movq $0, %rax # hidden param for printf
		movq $0, %rsi # clear %rsi, so that we can store the character to print inside
		movb %bl, %sil # copy the last byte of %rbx (which is the last byte of the quadword - the character) into the last byte of %rsi
		movq $string, %rdi # pass the string as param
		call printf
		decq %r13 # decrement the counter
		cmpq $0, %r13 # compare the counter to 0
		jg while # if the counter is still greater than 0 - loop again

	shr $16, %rbx # shift the original quad by two bytes to get the index of the next quad
	movq $0, %r13 # clear %r13 so that we can store the next index
	movl %ebx, %r13d # copy the last 4 bytes of %rbx (currently the index of the next location) into the last 4 bytes of %r13
	cmpq $0, %r13 # compare the index to 0
	je epilogue # if the index is 0 we need to terminate the subroutine so we jump to the epilogue

	movq $MESSAGE, %rdi # Load the base address of $MESSAGE into %rdi
	leaq (%rdi, %r13, 8), %rdi	# offset the base $MESSAGE address with the index in %r13 multiplied by 8 bytes (1 quad)
	call decode # call decode again with the next quad of the file

	epilogue:
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
