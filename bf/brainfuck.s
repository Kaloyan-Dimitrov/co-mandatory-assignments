.section .bss
    memory:			.skip 65536
    offset_stack:   		.skip 1024
    loop_buffer:    		.skip 65536
    good_carry:	    		.skip 8
    mul_deltas_left:		.skip 65536
    mul_deltas_middle:		.skip 1
    mul_deltas_right:		.skip 65536

.section .data
    format_str:	    .asciz "We should be executing the following code:\n%s"

    zero_loop_inc:  .ascii "[+]"
    zero_loop_dec:  .ascii "[-]"

    # syscalls
    .equiv SYS_READ, 0
    .equiv SYS_WRITE, 1

    # memory protection flags
    .equiv PROT_READ, 0x1
    .equiv PROT_WRITE, 0x2
    .equiv PROT_EXEC, 0x4
    
    # memory map flags
    .equiv MAP_PRIVATE, 0x02
    .equiv MAP_ANONYMOUS, 0x20

    # max program size
    .equiv PROG_SIZE, 8388608 

    # brainfuck tokens
    .equiv TOK_INC,	'+'
    .equiv TOK_DEC,	'-'
    .equiv TOK_INC_PC,	'>'
    .equiv TOK_DEC_PC,	'<'
    .equiv TOK_READ,	','
    .equiv TOK_WRITE,	'.'
    .equiv TOK_JZ,	'['
    .equiv TOK_JNZ,	']'
    .equiv TOK_NULL,	0

.section .text
    .global brainfuck

op_init:
    pushq %rbp
    movq %rsp, %rbp
    leaq memory, %r15
    .equiv op_init_len, . - op_init

op_inc:
    addb $42, (%r15)
    .equiv op_inc_len, . - op_inc

op_dec:
    subb $42, (%r15)
    .equiv op_dec_len, . - op_dec

op_inc_pc:
    addq $42, %r15
    .equiv op_inc_pc_len, . - op_inc_pc

op_dec_pc:
    subq $42, %r15
    .equiv op_dec_pc_len, . - op_dec_pc

op_mov:
    movb (%r15), %al
    addb %al, 42(%r15)
    .equiv op_mov_len, . - op_mov

op_mul:
    movl $42, %eax
    imulb (%r15)
    addq %rax, 42(%r15)
    .equiv op_mul_len, . - op_mul

op_zero:
    movb $0, (%r15)
    .equiv op_zero_len, . - op_zero

op_read:
    movl $1, %edx
    movq %r15, %rsi
    xorl %edi, %edi
    movq $SYS_READ, %rax
    syscall
    .equiv op_read_len, . - op_read

op_write:
    movl $1, %edx
    movq %r15, %rsi
    movl $1, %edi
    movl $SYS_WRITE, %eax
    syscall
    .equiv op_write_len, . - op_write

op_cmpz:
    cmpb $0, (%r15)
    .equiv op_cmpz_len, . - op_cmpz

# op_je_short:
#     .byte 0x74
#     .byte 0x00
#     .equiv op_je_short_len, . - op_je_short

op_je_near:
    .byte 0x0F, 0x84
    .long 0x00000000
    .equiv op_je_near_len, . - op_je_near

# op_jne_short:
#     .byte 0x75
#     .byte 0x00
#     .equiv op_jne_short_len, . - op_jne_short

op_jne_near:
    .byte 0x0F, 0x85
    .long 0x00000000
    .equiv op_jne_near_len, . - op_jne_near

op_ret:
    movq %rbp, %rsp
    popq %rbp
    ret
    .equiv op_ret_len, . - op_ret

# void *emit(void *addr, void *symbol, size_t len)
emit_symbol:
    pushq %rbp
    movq %rsp, %rbp
    
    # Move bytes
    movq %rdx, %rcx
    rep movsb

    # Return new program pointer
    movq %rdi, %rax

    movq %rbp, %rsp
    popq %rbp
    ret

# void backpatch_inc_dec(void* addr, int8_t value)
backpatch_inc_dec:
    pushq %rbp
    movq %rsp, %rbp

    addq $3, %rdi
    movb %sil, (%rdi)

    movq %rbp, %rsp
    popq %rbp
    ret

# void backpatch_jmp_near(void* addr, int32_t value)
backpatch_jmp_near:
    pushq %rbp
    movq %rsp, %rbp

    addq $2, %rdi
    movl %esi, (%rdi)

    movq %rbp, %rsp
    popq %rbp
    ret

# void backpatch_mov(void* addr, int8_t value)
backpatch_mov:
    pushq %rbp
    movq %rsp, %rbp

    addq $6, %rdi
    movb %sil, (%rdi)

    movq %rbp, %rsp
    popq %rbp
    ret

# void backpatch_mul(void* addr, int8_t mult, int8_t offset)
backpatch_mul:
    pushq %rbp
    movq %rsp, %rbp

    addq $1, %rdi
    movb %sil, (%rdi)
    addq $10, %rdi
    movb %dl, (%rdi)

    movq %rbp, %rsp
    popq %rbp
    ret

# size_t*, size_t emit_mul(size_t *delta_start, size_t delta_offset)
emit_mul:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    movq %rdi, -8(%rbp)

    # Add to the offset to be safe
    addq $4, %rsi

    movq %rdi, %r8
    subq %rsi, %r8

    movq %rdi, %r9
    addq %rsi, %r9
    
    xorl %r10d, %r10d
    delta_loop:
	incq %r8
	movb (%r8), %r10b

	cmpq %r8, -8(%rbp)
	je delta_loop

	cmpq %r8, %r9
	je delta_loop_end

	testb %r10b, %r10b
	jz delta_loop

	cmpb $1, %r10b
	jne non_one_mult

	movq $op_mov_len, %rdx
	leaq op_mov, %rsi
	movq %rbx, %rdi
	call emit_symbol

	movq %rbx, %rdi # void *addr
	movq %rax, %rbx

	movq %r8, %rsi # int8_t value
	subq -8(%rbp), %rsi

	call backpatch_mov
	
	jmp delta_loop
	non_one_mult:
	movq $op_mul_len, %rdx
	leaq op_mul, %rsi
	movq %rbx, %rdi
	call emit_symbol

	movq %rbx, %rdi # void *addr
	movq %rax, %rbx

	movb %r10b, %sil # int8_t mult

	movq %r8, %rdx # int8_t offset
	subq -8(%rbp), %rdx
	call backpatch_mul
	
	jmp delta_loop
    delta_loop_end:	

    # Zero initial cell
    movq $op_zero_len, %rdx
    leaq op_zero, %rsi
    movq %rbx, %rdi
    call emit_symbol

    movq %rbp, %rsp
    popq %rbp
    ret

optimize_mul:
    pushq %rbp
    movq %rsp, %rbp

    xchg %rdi, %rsi
    call check_mul_opt
    test %rax, %rax
    jz optimize_mul_end

    movq %rax, %rdi # int8_t *deltas
    movq %rdx, %rsi # int64_t delta_offset
    call emit_mul

    optimize_mul_end:
    movq %rbp, %rsp
    popq %rbp
    ret

# Returns: 0 if false
is_mul_loop:
	push %rbp
	mov %rsp, %rbp
	sub $16, %rsp
	mov %r12, -16(%rbp)
	mov %rdi, %r12												# Save the pointer to the start of the loop

	mov $']', %rsi
	call strchr														# Search for closing loop bracket

	cmpq $0, %rax
	je end_invalid_multiplication_loop		# If closing loop bracket not found, return false

	cmpb $'-', 1(%r12)
	jne end_invalid_multiplication_loop		# If the first character is not a decrement, return false

	# copy the string to a buffer
	mov $loop_buffer, %rdi
	sub %r12, %rax 												# Calculate the length of the loop string
	inc %rax
	mov %r12, %rsi
	mov %rax, %rdx
	strc:
	call strncpy

	mov $loop_buffer, %rdi
	inc %rdi															# Skip the opening loop bracket in the search
	mov $'[', %rsi
	call strchr														# Search for opening loop bracket
	cmpq $0, %rax
	jne end_invalid_multiplication_loop		# If opening loop bracket is found, return false

	mov $loop_buffer, %rdi
	inc %rdi															# Skip the opening loop bracket in the search
	mov $'.', %rsi
	call strchr														# Search for the .
	cmpq $0, %rax
	jne end_invalid_multiplication_loop		# If the . is found, return false

	mov $loop_buffer, %rdi
	inc %rdi															# Skip the opening loop bracket in the search
	mov $',', %rsi
	call strchr														# Search for the ,
	cmpq $0, %rax
	jne end_invalid_multiplication_loop		# If the , is found, return false

	# Ensure net pointer movement - check that the number of '>' and '<' are equal	
	mov $loop_buffer, %rdi
	call strlen

	mov %rax, %rcx
	dec %rcx 															# Subtract 1 from the length to get the last valid index
	mov $loop_buffer, %rdx
	mov $0, %rdi
	mov $0, %rsi
	check_loop:
		cmpb $'<', (%rdx, %rcx)
		je increment_rdi

		cmpb $'>', (%rdx, %rcx)
		je increment_rsi

		jmp check_loop_loop

		increment_rdi:
			inc %rdi
			jmp check_loop_loop

		increment_rsi:
			inc %rsi
			jmp check_loop_loop

		check_loop_loop:
		loop check_loop

	cmp %rdi, %rsi
	jne end_invalid_multiplication_loop
	
	mov $1, %rax
	jmp end_valid_multiplication_loop

	end_invalid_multiplication_loop:
		movq $0, %rax
	end_valid_multiplication_loop:
	mov -16(%rbp), %r12
	mov %rbp, %rsp
	pop %rbp
	ret

# Arguments: %rdi - pointer to the start of the loop
# Returns: %rax - pointer to the middle of the deltas array, %rdx - offset to the larger end of the array 
# memset memory
check_mul_opt:
	push %rbp
	mov %rsp, %rbp
	sub $16, %rsp

	mov %r11, -8(%rbp)
	mov %r12, -16(%rbp)

	mov %rdi, %r12
	call is_mul_loop
	cmp $0, %rax
	je end_parse_multiplication_loop

	movl $131073, %edx
	xorl %esi, %esi
	leaq mul_deltas_left, %rdi
	call memset

	mov $mul_deltas_middle, %rdi
	mov $loop_buffer, %rsi
	inc %rsi

	mov $0, %r11 # This is the max offset to the larger end of the array

	mulloop_parse_loop:
		cmpb $0, (%rsi)
		je end_mulloop_parse_loop

		mov %rdi, %rax
		sub $mul_deltas_middle, %rax
		cmp $0, %rax
		jge compare_max_offset
		mov $-1, %r8
		mul %r8

		compare_max_offset:
			cmp %r11, %rax
			jge update_max_offset
			jmp mulloop_parse_char

		update_max_offset:
			mov %rax, %r11

		mulloop_parse_char:
		movb (%rsi), %cl

		cmp $'>', %cl
		je increment_pointer

		cmp $'<', %cl
		je decrement_pointer

		cmp $'+', %cl
		je increment_current_cell

		cmp $'-', %cl
		je decrement_current_cell

		jmp end_mulloop_parse_loop

		increment_pointer:
			inc %rdi
			inc %rsi
			jmp mulloop_parse_loop

		decrement_pointer:
			dec %rdi
			inc %rsi
			jmp mulloop_parse_loop

		increment_current_cell:
			incb (%rdi)
			inc %rsi
			jmp mulloop_parse_loop

		decrement_current_cell:
			decb (%rdi)
			inc %rsi
			jmp mulloop_parse_loop

	end_mulloop_parse_loop:
		mov $mul_deltas_middle, %rax
		mov %r11, %rdx
		cmpb $-1, (%rdi)
		je end_parse_multiplication_loop
		mov $0, %rax

	end_parse_multiplication_loop:
	mov -16(%rbp), %r12
	mov -8(%rbp), %r11
	mov %rbp, %rsp
	pop %rbp
	ret

# Your brainfuck subroutine will receive one argument:
# a zero termianted string containing the code to execute.
brainfuck:
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp
    
    # Save pointer to code on stack
    movq %rdi, -8(%rbp)

    call print_code

    movq -8(%rbp), %rdi # const char *code
    call compile_code

    movq %rax, %rdi # void *bytecode
    call execute_bytecode

    movq %rbp, %rsp
    popq %rbp
    ret

# void print_code(const char *code)
print_code:
    pushq %rbp
    movq %rsp, %rbp

    movq %rdi, %rsi
    movq $format_str, %rdi
    xorl %eax, %eax
    call printf

    movq %rbp, %rsp
    popq %rbp
    ret

# void *compile_code(const char *code)
compile_code:
    pushq %rbp
    movq %rsp, %rbp
    subq $48, %rsp

    # Save pointer to code
    movq %rdi, -8(%rbp)

    # Allocate memory for program
    # void *mmap(void addr[.length], size_t length, int prot, int flags, int fd, off_t offset);
    xorl %r9d, %r9d # off_t offset
    movq $-1, %r8 # int fd
    xorl %ecx, %ecx # int flags
    orq $MAP_PRIVATE, %rcx
    orq $MAP_ANONYMOUS, %rcx
    xorl %edx, %edx # int prot
    orq $PROT_READ, %rdx
    orq $PROT_WRITE, %rdx
    movq $PROG_SIZE, %rsi # size_t length
    xorl %edi, %edi # void *addr
    call mmap

    # Save pointer to allocated memory
    movq %rax, -16(%rbp)

    # Move pointer to program memory to caller-saved register
    movq %rax, %rbx

    # Restore pointer to code
    movq -8(%rbp), %r10

    # Initialize pointer to offset stack
    leaq offset_stack, %r12
    xorl %r15d, %r15d

    movq $op_init_len, %rdx
    leaq op_init, %rsi
    movq %rbx, %rdi
    call emit_symbol
    movq %rax, %rbx

    # Code offset
    xorl %r13d, %r13d
    compile_loop:
	xorl %r8d, %r8d
	movb (%r10, %r13, 1), %r8b

	# Store old index for repeating operations
	movq %r13, %r11

	cmpq $TOK_INC, %r8
	je compile_inc

	cmpq $TOK_DEC, %r8
	je compile_dec

	cmpq $TOK_INC_PC, %r8
	je compile_inc_pc

	cmpq $TOK_DEC_PC, %r8
	je compile_dec_pc

	cmpq $TOK_READ, %r8
	je compile_read

	cmpq $TOK_WRITE, %r8
	je compile_write

	cmpq $TOK_JZ, %r8
	je compile_jz

	cmpq $TOK_JNZ, %r8
	je compile_jnz

	cmpq $TOK_NULL, %r8
	je compile_loop_end

	incq %r13
	jmp compile_loop
	
    compile_inc:
	incq %r11
	movb (%r10, %r11, 1), %r9b
	cmpb $TOK_INC, %r9b
	je compile_inc

	subq %r13, %r11

	movq %rax, %r14

	# emit op_inc op_inc_len
	movq $op_inc_len, %rdx
	leaq op_inc, %rsi
	movq %rbx, %rdi
	call emit_symbol
	movq %rax, %rbx

	movq %r14, %rdi
	movb %r11b, %sil
	call backpatch_inc_dec

	movq $1, good_carry

	addq %r11, %r13
	jmp compile_loop
    compile_dec:
	incq %r11
	movb (%r10, %r11, 1), %r9b
	cmpb $TOK_DEC, %r9b
	je compile_dec

	subq %r13, %r11

	movq %rbx, %r14

	movq $op_dec_len, %rdx
	leaq op_dec, %rsi
	movq %rbx, %rdi
	call emit_symbol
	movq %rax, %rbx

	movq %r14, %rdi
	movb %r11b, %sil
	call backpatch_inc_dec

	movq $1, good_carry

	addq %r11, %r13
	jmp compile_loop
    compile_zero:
	movq $op_zero_len, %rdx
	leaq op_zero, %rsi
	movq %rbx, %rdi
	call emit_symbol
	movq %rax, %rbx
	
	movq $0, good_carry

	addq $3, %r13
	jmp compile_loop
    compile_inc_pc:
	incq %r11
	movb (%r10, %r11, 1), %r9b
	cmpb $TOK_INC_PC, %r9b
	je compile_inc_pc

	subq %r13, %r11

	movq %rbx, %r14

	movq $op_inc_pc_len, %rdx
	leaq op_inc_pc, %rsi
	movq %rbx, %rdi
	call emit_symbol
	movq %rax, %rbx

	movq %r14, %rdi
	movb %r11b, %sil
	call backpatch_inc_dec

	movq $0, good_carry

	addq %r11, %r13
	jmp compile_loop
    compile_dec_pc:
	incq %r11
	movb (%r10, %r11, 1), %r9b
	cmpb $TOK_DEC_PC, %r9b
	je compile_dec_pc

	subq %r13, %r11

	movq %rbx, %r14

	movq $op_dec_pc_len, %rdx
	leaq op_dec_pc, %rsi
	movq %rbx, %rdi
	call emit_symbol
	movq %rax, %rbx

	movq %r14, %rdi
	movb %r11b, %sil
	call backpatch_inc_dec

	movq $0, good_carry

	addq %r11, %r13
	jmp compile_loop
    compile_read:
	movq $op_read_len, %rdx
	leaq op_read, %rsi
	movq %rbx, %rdi
	call emit_symbol
	movq %rax, %rbx

	movq $0, good_carry

	incq %r13
	jmp compile_loop
    compile_write:
	movq $op_write_len, %rdx
	leaq op_write, %rsi
	movq %rbx, %rdi
	call emit_symbol
	movq %rax, %rbx

	movq $0, good_carry

	incq %r13
	jmp compile_loop
    compile_jz:
	movq %r10, -32(%rbp)
	movq %r11, -24(%rbp)

	movq %r10, %rsi
	addq %r13, %rsi
	movq %rbx, %rdi	
	call optimize_mul

	# Check if we compiled the loop
	testq %rax, %rax
	jz mul_no_opt

	movq -32(%rbp), %r10
	movq -24(%rbp), %r11

	xorl %r9d, %r9d

	# Move new pointer to program and code
	movq %rax, %rbx
	mul_opt_move_forward:
	    incq %r13
	    movb (%r10, %r13, 1), %r9b
	    cmpb $TOK_JNZ, %r9b
	    jne mul_opt_move_forward
	incq %r13

	jmp compile_loop
	mul_no_opt:

	# Check for [+]
	movq $3, %rdx
	movq %r10, %rsi
	addq %r11, %rsi
	leaq zero_loop_inc, %rdi
	call strncmp

	movq -32(%rbp), %r10
	movq -24(%rbp), %r11

	test %rax, %rax
	je compile_zero

	# Check for [-]
	movq $3, %rdx
	movq %r10, %rsi
	addq %r11, %rsi
	leaq zero_loop_dec, %rdi
	call strncmp

	movq -32(%rbp), %r10
	movq -24(%rbp), %r11

	test %rax, %rax
	je compile_zero

	movq good_carry, %rax
	cmpq $0, %rax
	jne compile_jz_skip_cmp

	movq $op_cmpz_len, %rdx
	leaq op_cmpz, %rsi
	movq %rbx, %rdi
	call emit_symbol
	movq %rax, %rbx
	compile_jz_skip_cmp:

	# Save address before jump to offset stack
	movq %rbx, (%r12, %r15, 8)
	incq %r15

	movq $op_je_near_len, %rdx
	leaq op_je_near, %rsi
	movq %rbx, %rdi
	call emit_symbol
	movq %rax, %rbx

	incq %r13
	jmp compile_loop
    compile_jnz:
	movq good_carry, %rax
	cmpq $0, %rax
	jne compile_jnz_skip_cmp

	movq $op_cmpz_len, %rdx
	leaq op_cmpz, %rsi
	movq %rbx, %rdi
	call emit_symbol
	movq %rax, %rbx
	compile_jnz_skip_cmp:

	movq $op_jne_near_len, %rdx
	leaq op_jne_near, %rsi
	movq %rbx, %rdi
	call emit_symbol
	movq %rax, %rbx

	decq %r15
	movq (%r12, %r15, 8), %rdi
	movq %rdi, -24(%rbp)

	movq %rbx, %rsi
	subq %rdi, %rsi                    # %rdi = distance from '[' to ']'
	subq $op_jne_near_len, %rsi

	# Patch 'je' displacement
	call backpatch_jmp_near

	movq -24(%rbp), %rdi

	# Calculate displacement for 'jne' at ']'
	addq $op_je_near_len, %rdi         # %rdi = address after 'je' instruction
	subq %rbx, %rdi			   # %rcx = displacement

	# Patch 'jne' displacement
	movl %edi, %esi
	movq %rbx, %rdi
	subq $op_jne_near_len, %rdi
	call backpatch_jmp_near

	incq %r13
	jmp compile_loop
    compile_loop_end:
	movq $op_ret_len, %rdx
	leaq op_ret, %rsi
	movq %rbx, %rdi
	call emit_symbol

    movq -16(%rbp), %rax

    movq %rbp, %rsp
    popq %rbp
    ret

# void execute_bytecode(void *bytecode)
execute_bytecode:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    # Save the pointer to our code on the stack
    movq %rdi, -8(%rbp)

    # Make the program memory executable
    # int mprotect(void addr[.len], size_t len, int prot);
    xorl %edx, %edx # int prot
    orq $PROT_READ, %rdx
    orq $PROT_EXEC, %rdx
    movq $PROG_SIZE, %rsi # size_t len
    # movq $rdi, %rdi # void *addr
    call mprotect

    # Restore the pointer to our code
    movq -8(%rbp), %r14

    call * %r14

    movq %rbp, %rsp
    popq %rbp
    ret
