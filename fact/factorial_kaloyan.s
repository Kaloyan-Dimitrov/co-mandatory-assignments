	.data
	title: .asciz "Names: Kaloyan Dimitrov, Mihail Mihov. NetIDs: kmdimitrov, mmihov. Assignment: FACTORIAL\n"
	input_prompt: .asciz "Please input a NON-NEGATIVE number to get its factorial:\n"
	input_message: .asciz "%ld"
	result: .asciz "The result is %ld\n"

	.text
	.global main

	main:
		# prologue
		pushq %rbp # push the previous base pointer to the stack
		movq %rsp, %rbp # move (copy) the existing stack pointer to the base pointer
		subq $16, %rsp # allocate space for the input (one 8-byte integer)

		# print the welcome message
		movq $0, %rax # hidden param: no vector registers in use for printf
		movq $title, %rdi # param1 of printf: the format string
		call printf	

		input_while:
			# print the prompt
			movq $0, %rax # hidden param: no vector registers in use for printf
			movq $input_prompt, %rdi # param1 of printf: the format string
			call printf
			# read the input (base and exponent)
			leaq -16(%rbp), %rsi # set the address of the first input (base) to -8 bytes from the base pointer
			movq $input_message, %rdi # param1 of printf: the format string
			movq $0, %rax # hidden param: no vector registers in use for scanf
			call scanf
			cmpq $0, -16(%rbp) # compare the input to 0
			jl input_while # if the input is less than - ask for input again

		movq -16(%rbp), %rdi # move the first input from the stack as the base param
		movq $1, %rax # set the inital value of RAX (which will keep the result) to 1
		call factorial

		# print the result
		movq %rax, %rsi # param2 of printf: the result
		movq $0, %rax # hidden param: no vector registers in use for printf
		movq $result, %rdi # param1 of printf: the format string
		call printf

		# epilogue
		addq $16, %rsp # deallocate the space for the input
		movq %rbp, %rsp # move (copy) the base pointer into the stack pointer
		popq %rbp # pop the previous base pointer from the stack

		movq $0, %rdi # specify the 0 exit code
		call exit # call the exit system call

	/**

			/**
			* The factorial subroutine calculates the factorial
			* of a non-negative number using recursion.
			*
			* Arguments:
			*
			* 	number - the target factorial number
			*
			* Return value: the factorial of 'number'.
			/

			int factorial(int number) {
				if(number == 0)
					return 1;
				return number * factorial(number - 1);
			}

	*/


	factorial:
		# prologue
		pushq %rbp # save the old base pointer
		movq %rsp, %rbp # set the new base pointer
		subq $8, %rsp # allocate space for the value of the recursive call to factorial

		cmpq $0, %rdi # compare the input to 0
		je factorial_end # if the input is equal to 0 - we are done

		pushq %rdi # push the input to the stack
		dec %rdi # decrement the input
		call factorial
		mulq (%rsp) # multiply the result of the recursive call (%rax) by the last pushed value of the stack

		# epilogue
		addq $8, %rsp # deallocate the for the value of the recursive call to factorial
		movq %rbp, %rsp # move (copy) the base pointer into the stack pointer
		popq %rbp # pop the previous base pointer from the stack
		ret

		factorial_end:
			movq $1, %rax # return 1 (the base of the recursion)
			# epilogue
			addq $8, %rsp # deallocate the space for the input
			movq %rbp, %rsp # move (copy) the base pointer into the stack pointer
			popq %rbp # pop the previous base pointer from the stack
			ret