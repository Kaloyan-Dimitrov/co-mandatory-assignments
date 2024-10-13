.section .bss
    memory:	    .skip 65536
    offset_stack:   .skip 1024
    good_carry:	    .skip 8

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
    addb $1, (%r15)
    .equiv op_inc_len, . - op_inc

op_dec:
    subb $1, (%r15)
    .equiv op_dec_len, . - op_dec

op_inc_pc:
    addq $1, %r15
    .equiv op_inc_pc_len, . - op_inc_pc

op_dec_pc:
    subq $1, %r15
    .equiv op_dec_pc_len, . - op_dec_pc

op_zero:
    movb $0, (%r15)
    .equiv op_zero_len, . - op_zero

op_read:
    movq $1, %rdx
    movq %r15, %rsi
    movq $0, %rdi
    movq $SYS_READ, %rax
    syscall
    .equiv op_read_len, . - op_read

op_write:
    movq $1, %rdx
    movq %r15, %rsi
    movq $1, %rdi
    movq $SYS_WRITE, %rax
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
    movq $0, %rax
    call printf

    movq %rbp, %rsp
    popq %rbp
    ret

# void *compile_code(const char *code)
compile_code:
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp

    # Save pointer to code
    movq %rdi, -8(%rbp)

    # Allocate memory for program
    # void *mmap(void addr[.length], size_t length, int prot, int flags, int fd, off_t offset);
    movq $0, %r9 # off_t offset
    movq $-1, %r8 # int fd
    movq $0, %rcx # int flags
    orq $MAP_PRIVATE, %rcx
    orq $MAP_ANONYMOUS, %rcx
    movq $0, %rdx # int prot
    orq $PROT_READ, %rdx
    orq $PROT_WRITE, %rdx
    movq $PROG_SIZE, %rsi # size_t length
    movq $0, %rdi # void *addr
    call mmap

    # Save pointer to allocated memory
    movq %rax, -16(%rbp)

    # Move pointer to program memory to caller-saved register
    movq %rax, %rbx

    # Restore pointer to code
    movq -8(%rbp), %r10

    # Initialize pointer to offset stack
    leaq offset_stack, %r12
    movq $0, %r15

    movq $op_init_len, %rdx
    leaq op_init, %rsi
    movq %rbx, %rdi
    call emit_symbol
    movq %rax, %rbx

    # Code offset
    movq $0, %r13
    compile_loop:
	movq $0, %r8
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
	# Check for [+]
	movq $3, %rdx
	movq %r10, %rsi
	addq %r11, %rsi
	leaq zero_loop_inc, %rdi
	call strncmp

	test %rax, %rax
	je compile_zero

	# Check for [-]
	movq $3, %rdx
	movq %r10, %rsi
	addq %r11, %rsi
	leaq zero_loop_dec, %rdi
	call strncmp

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
    movq $0, %rdx # int prot
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
