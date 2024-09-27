

.data
    format_string: .asciz "My name is %s. I think I’ll get a %u for my exam. What does %r do? And %%?\n"
    name_string: .asciz "Piet"
    exam_result: .quad 10
    digit: .asciz "Hey this is: %d\n"
 
.section .bss
.lcomm int_buffer, 21  # Buffer to hold integer strings (max 20 digits + null terminator)
 
.text
 
.global main
 
debug_print:
    push %rbp
    movq %rsp, %rbp
 
    push %rax
    push %rdi
    push %rsi
    push %rdx
    push %rcx
    push %r8
    movq $digit, %rdi
    movq %r15, %rsi
    movq $0, %rax
    call printf
    pop %r8
    pop %rcx
    pop %rdx
    pop %rsi
    pop %rdi
    pop %rax
 
    movq %rbp, %rsp
    pop %rbp
    ret
 
# int len(char *string)
# Input: %rdi - pointer to null-terminated strings
# Output: %rax - length of the string
len:
    pushq %rbp                           # Prologue
    movq %rsp, %rbp
 
    movq %rdi, %rsi                      # Save the pointer to the string
    movq $0, %rax                        # Initialize length to 0
 
    len_loop:
    	movb (%rdi, %rax), %dl           # Load byte from string
    	cmpb $0, %dl                     # Check for null terminator
    	je len_done
    	incq %rax                        # Increment length
    	jmp len_loop
 
    len_done:                            # Epilogue
        movq %rbp, %rsp
        popq %rbp
        ret
 
# Simplified write syscall wrapper
# Input: %rdi - file descriptor, %rsi - buffer, %rdx - count
# Output: %rax - number of bytes written
sys_write:
    movq $1, %rax         # syscall number for write
    syscall
    ret
 
# void reverse_string(char *str, int length)
# Input: %rdi - pointer to string, %rsi - length of the string
reverse_string:
    pushq %rbp
    movq %rsp, %rbp
 
    movq %rdi, %rdx                 # Set %rdx to the pointer of the string
    movq %rsi, %rcx                 # Copy the length of the string from %rsi to %rcx
    decq %rcx	                    # Subtract 1 from %rcx to get the last
                                    # valid index (before the null-terminator)
    movq $0, %r8                    # counter (initialized to 0)
 
    reverse_loop:
        cmpq %r8, %rcx              # If end <= start - we are done (we increment %r8 from the start
                                    # of the string and decrement %rcx from the end of the string)
        jle reverse_done
 
        # Swap characters at positions %r8 and %rcx
        movb (%rdx, %r8, 1), %al       # Copy the character at position %r8 by offsetting from %rdx into %al
        movb (%rdx, %rcx, 1), %bl      # Copy the character at position %rcx by offsetting from %rdx into %bl
 
        leaq (%rdx, %r8, 1), %r14
        movb %bl, (%r14)            # Swap the two characters
        leaq (%rdx, %rcx, 1), %r14
        movb %al, (%r14)
 
        incq %r8
	decq %rcx
        jmp reverse_loop
 
    reverse_done:
        movq %rbp, %rsp
        popq %rbp
        ret
 
# void int_to_string(int64_t num, char *buffer)
# Input: %rdi - integer to convert, %rsi - pointer to buffer
signed_int_to_string:
    # prologue
    pushq %rbp
    movq %rsp, %rbp
 
    movq %rdi, %rax             # Put the number in %rax
    movq %rsi, %rdi             # %rdi = buffer pointer
 
    movq $1, %rsi               # Flag that we are converting a signed integer
                                # for the int_to_string_convert subroutine
    cmpq $0, %rax               # check specifically for zero
    jne int_to_string_convert   # if not 0 start converting the number otherwise return the string "0"
    movb $'0', (%rdi)           # copy the character literal '0' into the buffer
                                # the location of which is stored in %rdi
    movb $0, 1(%rdi)            # attach a terminating character (0) at the end of the string
 
    #epilogue
    movq %rbp, %rsp
    popq %rbp
    ret
 
int_to_string_convert:
    # Initialize variables
    movq %rax, %rcx             # %rcx = num
    movq $0, %rdx               # %rdx is the remainder (initialized as 0)
    movq $0, %r8                # %r8 is the index of the digit which
                                # we are currently parsing (initialized as 0)
    # movb $0, (%rdi)             # Null-terminate buffer
 
    # Check if we are converting a signed integer
    movq $0, %rbx               # Initialize the sign as 0 (+)
    cmpq $0, %rsi               # Check the flag for signed/unsigned (1/0) integer
    je int_to_string_loop
 
    movq %rax, %rbx             # Copy the number again in the %rbx
                                # to check if it is negative
    shrq $63, %rbx              # Shift to the first bit of the number to check it's sign
 
    cmpq $0, %rbx               # Check if the first bit in %rbx is
                                # 0 - the number is positive, 1 - the number is negative
    je int_to_string_loop
 
    negq %rcx                   # Invert the number if it is negative
    decq %rcx                   # also subtract 1 because the number was in 2C
 
int_to_string_loop:             # Convert number to string
    movq $0, %rdx               # Clear %rdx where the result of the division will be stored
    movq $10, %r9               # Set the dividend to our number (%rcx)
    divq %r9                    # %rax = num / 10, %rdx = num % 10 - so our character
                                # is in the lowest byte of the %rdx register
 
    addb $'0', %dl              # Convert the digit to a character by adding
                                # the digit to the ASCII code of the number '0'
    movb %dl, (%rdi, %r8)       # Store digit in buffer (we keep the address of the buffer in %rdi)
                                # offset by the index of the character
 
    incq %r8                    # Increment the index
    movq %rax, %rcx             # Update the number with the result from the division
                                # (the previous number without the last digit)
    cmpq $0, %rcx               # If the number is 0 - we have parsed all the digits
    jne int_to_string_loop
 
    cmpq $0, %rbx               # Check the sign again if it is equal to 0 - end the loop
    je int_to_string_reverse
    movb $'-', (%rdi, %r8)      # If the number was negative - add a minus to the buffer
    incq %r8                    # Increase the index in order to know the proper length of the string
 
int_to_string_reverse:
    movb $0, (%rdi, %r8)        # Null-terminate the buffer
 
    leaq (%rdi), %rdi           # Pass the string address to the reverse_string function
    movq %r8, %rsi              # Pass the length of the string to the reverse_string
    call reverse_string
 
    movq %rbp, %rsp             # epilogue
    popq %rbp
    ret
 
# void utoa(uint64_t num, char *buffer)
# Input: %rdi - unsigned integer to convert, %rsi - pointer to buffer
unsigned_int_to_string:
    # prologue
    pushq %rbp
    movq %rsp, %rbp
 
    movq %rdi, %rax             # Copy the number into %rax because that is
                                # where int_to_string_convert expects it
    movq %rsi, %rdi             # %rdi = buffer pointer
 
    cmpq $0, %rdi               # Check explicitly if the number is 0
    jne int_to_string_convert
 
    movb $'0', %sil
    movb $0, 1(%rsi)
 
    # epilogue
    movq %rbp, %rsp
    pop %rbp
    ret
 
 
# char* print_until_specifier(char *string)
# %rdi - string (null-terminated)
# returns pointer to last printed character
print_until_specifier:
    pushq %rbp
    movq %rsp, %rbp
 
    movq $0, %rcx                              # reset the counter
    loop_until_specifier:
    	movb (%rdi, %rcx, 1), %dl              # copy into %dl (the lowest byte in %rdx) the next character which is taken from
    	                                       # (the starting address) %rdi + (the counter - number of chars offset) %rcx * 1
    	cmpb $37, %dl                          # if the next character is '%' we exit the loop - we have reached a specifier
    	je loop_until_specifier_end
    	cmpb $0, %dl                           # if the next character is '\0' (string terminator) - we exit the loop - the string is finished
    	je loop_until_specifier_end
 
    	incq %rcx                              # otherwise we increment the counter - go to the next character
    	jmp loop_until_specifier
 
        loop_until_specifier_end:
 
        movq %rcx, %rdx # len
        movq %rdi, %rsi # buf
        movq $1, %rdi # stdout
        call sys_write
 
    # return pointer to last printed character
    lea (%rdi, %rcx, 1), %rax
 
    movq %rbp, %rsp
    popq %rbp
 
    ret
 
# void print_string(char *string)
# %rdi - string (null-terminated)
print_string:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
 
    movq %rdi, -8(%rbp)
    call len
 
    movq %rax, %rdx                 # len
    movq -8(%rbp), %rsi             # string
    movq $1, %rdi                   # stdout
    call sys_write
 
    movq %rbp, %rsp
    popq %rbp
 
    ret
 
# handle specifier
 
# printf(char *format_string, ...)
# %rdi - format_string
# %rsi - 1st argument
# %rdx - 2nd argument
# %rcx - 3rd argument
# %r8 - 4th argument
# %r9 - 5th argument
# printf with %d %u %s and %% specifiers
my_printf:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
 
    # store string to stack
    movq %rdi, -8(%rbp)
 
    # store arguments processed
    movq $0, %rbx
    print_loop:
    	movq -8(%rbp), %rdi
    	call print_until_specifier
    	movq %rax, %rdi
    	call handle_specifier
    	movq $1, %r10
    	cmpb $0, (%rdi, %r10, 1)
    	je print_loop_end
    	jmp print_loop
 
    print_loop_end:
    # exit syscall
    movq $0, %rdi
    movq $60, %rax
    syscall
 
    movq %rbp, %rsp
    popq %rbp
 
    ret
 
handle_specifier:
    pushq %rbp
    movq %rsp, %rbp
 
    # movb (%rdi), %al
 
    # Compare and handle each specifier
    cmpb $'s', %al
    # je handle_string
 
    cmpb $'u', %al
    # je handle_unsigned
 
    cmpb $'r', %al
    # je handle_unknown
 
    cmpb $'%', %al
    # je handle_percent
 
    # Default case for unrecognized specifiers
    # jmp handle_unknown
 
 
 
main:
    pushq %rbp
    movq %rsp, %rbp
 
    # call our printf
    leaq format_string(%rip), %rdi  # %rdi = format string
    leaq name_string(%rip), %rsi    # %rsi = "Piet"
    movq exam_result(%rip), %rdx    # %rdx = 10
    # call my_printf
    movq $7583, %rdi                # Number to convert
    leaq int_buffer(%rip), %rsi     # Buffer to store string
    call signed_int_to_string       # Convert integer to string
 
    # Print the string
    leaq int_buffer(%rip), %rdi     # %rdi = buffer
    call print_string
 
 
    # exit syscall
    movq $0, %rdi
    movq $60, %rax
    syscall
 
    movq %rbp, %rsp
    popq %rbp
 
    ret
