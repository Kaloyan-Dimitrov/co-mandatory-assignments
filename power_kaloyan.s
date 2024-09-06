.text
title: .asciz "Names: Kaloyan Dimitrov, Mihail Mihov. NetIDs: kmdimitrov, mmihov. Assignment: POWERS\nPlease input a base and an exponent (both should be non-negarive):\n"
input_message: .asciz "%ld %ld"
result: .asciz "The result is %ld\n"
.global main

main:
	# prologue
	pushq %rbp # push the previous base pointer to the stack
	movq %rsp, %rbp # move (copy) the existing stack pointer to the base pointer
	subq $16, %rsp # allocate space for the input (two 8-byte integers)

	# print the welcome message
	movq $0, %rax # hidden param: no vector registers in use for printf
	movq $title, %rdi # param1 of printf: the format string
	call printf	

	# read the input (base and exponent)
	leaq -8(%rbp), %rsi # set the address of the first input (base) to -8 bytes from the base pointer
	leaq -16(%rbp), %rdx # set the address of the second input (exponent) to -16 bytes from the base pointer
	movq $input_message, %rdi # param1 of printf: the format string
	movq $0, %rax # hidden param: no vector registers in use for scanf
	call scanf

	movq -16(%rbp), %rsi # move the second input from the stack as the exponenet param
	movq -8(%rbp), %rdi # move the first input from the stack as the base param
	call pow

	# print the result
	movq $0, %rax # hidden param: no vector registers in use for printf
	movq $result, %rdi # param1 of printf: the format string
	movq %rax, %rsi # param2 of printf: the result
	call printf

	# epilogue
	addq $16, %rsp # deallocate the space for the input
	movq %rbp, %rsp # move (copy) the base pointer into the stack pointer
	popq %rbp # pop the previous base pointer from the stack

	movq $0, %rdi # specify the 0 exit code
	call exit # call the exit system call

/**

		/**
		* The pow subroutine calculates powers
		* of non-negative bases and exponents.
		*
		* Arguments:
		*
		* 	base - the exponential base
		* 	exp - the exponent
		*
		* Return value: 'base' raised to the power of 'exp'.
		/

		int pow(int base, int exp) {
			int total = 1;
			while(exp > 0) {
				total *= base;
				exp--;
			}
			return total;
		}

*/

pow:
	# prologue
	pushq %rbp # save the old base pointer
	movq %rsp, %rbp # set the new base pointer

	movq $1, %rax # initialize rax as 1
	while:
		cmpq $0, %rsi # check if the exponent is 0
		je while_end

		mulq %rdi
		dec %rsi

		jmp while
	while_end:
		ret
