.global sha1_chunk

# void message_schedule(uint32_t w[80])
# %rdi - address of w
message_schedule:
    pushq %rbp
    movq %rsp, %rbp

    movl $16, %ecx
    message_schedule_loop:
	movl %ecx, %edx
	subl $3, %edx # i-3
	movl (%rdi, %rdx, 4), %esi # load w[i-3]
	subl $5, %edx # i-8
	xorl (%rdi, %rdx, 4), %esi # w[i-3] ^ w[i-8]
	subl $6, %edx # i-14
	xorl (%rdi, %rdx, 4), %esi # w[i-3] ^ w[i-8] ^ w[i-14]
	subl $2, %edx # i-16
	xorl (%rdi, %rdx, 4), %esi # w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16]
	
	roll $1, %esi
	movl %esi, (%rdi, %rcx, 4)
	
	incl %ecx # ++i
	cmpl $80, %ecx # i < 80
	jl message_schedule_loop

	movq %rbp, %rsp
	popq %rbp
	ret

# void sha1_chunk(uint32_t h[5], uint32_t w[80])
# %rdi - address of h
# %rsi - address of w
sha1_chunk:
    # prologue
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    # save call-clobbered registers
    movq %rsi, -8(%rbp)
    movq %rdi, -16(%rbp)

    # load w into %rdi for message_schedule
    xchg %rdi, %rsi
    call message_schedule

    # restore call-clobbered registers
    movq -16(%rbp), %rdi
    movq -8(%rbp), %rsi 

    movl (%rdi), %edx	    # a
    movl 4(%rdi), %r8d	    # b
    movl 8(%rdi), %r9d	    # c
    movl 12(%rdi), %r10d   # d
    movl 16(%rdi), %r11d   # e

    # save callee-saved registers
    movq %r12, -8(%rbp)
    movq %r13, -16(%rbp)
    movq %r14, -24(%rbp)
    movq %r15, -32(%rbp)

    # Main loop
    movl $0, %ecx
    sha1_chunk_loop:
	# 0..19
	cmpl $20, %ecx
	jge l2
	    movl %r8d, %r12d # load b
	    andl %r9d, %r12d # (b & c)
	    movl %r8d, %r13d # load b
	    notl %r13d # (~b)
	    andl %r10d, %r13d # ((~b) & d)
	    orl	%r13d, %r12d # ((b & c) | ((~b) & d))
	    movl $0x5A827999, %r13d
	    jmp l4_end
	# 20..39
	l2:
	cmpl $40, %ecx
	jge l3
	    movl %r8d, %r12d # load b
	    xorl %r9d, %r12d # (b ^ c)
	    xorl %r10d, %r12d # ((b ^ c) ^ d)
	    movl $0x6ED9EBA1, %r13d
	    jmp l4_end
	# 40..59
	l3:
	cmpl $60, %ecx
	jge l4
	    movl %r8d, %r12d # load b
	    andl %r9d, %r12d # (b & c)
	    movl %r8d, %r13d # load b
	    andl %r10d, %r13d # (b & d)
	    orl %r13d, %r12d # ((b & c) | (b & d))
	    movl %r9d, %r13d # load c
	    andl %r10d, %r13d # (c & d)
	    orl %r13d, %r12d # (((b & c) | (b & d)) | (c & d))
	    movl $0x8F1BBCDC, %r13d
	    jmp l4_end
	# 60..79
	l4:
	    movl %r8d, %r12d # load b
	    xorl %r9d, %r12d # (b ^ c)
	    xorl %r10d, %r12d # ((b ^ c) ^ d)
	    movl $0xCA62C1D6, %r13d
	    jmp l4_end
	l4_end:
	
	# %r12 - f
	# %r13 - k
	# %r14 - temp
	movl %edx, %r14d # load a
	roll $5, %r14d # (a leftrotate 5)
	addl %r12d, %r14d # (a leftrotate 5) + f
	addl %r11d, %r14d # (a leftrotate 5) + f + e
	addl %r13d, %r14d # (a leftrotate 5) + f + e + k
	addl (%rsi, %rcx, 4), %r14d # (a leftrotate 5) + f + e + k + w[i]
	
	movl %r10d, %r11d # e = d
	movl %r9d, %r10d # d = c
	movl %r8d, %r15d # %r15 - b_rotated
	roll $30, %r15d # (b leftrotate 30)
	movl %r15d, %r9d # c = (b leftrotate 30)
	movl %edx, %r8d # b = a
	movl %r14d, %edx # a = temp
	
	incl %ecx # ++i
	cmpl $80, %ecx # i < 80
	jl sha1_chunk_loop
    addl %edx, (%rdi) # h[0] += a
    addl %r8d, 4(%rdi) # h[1] += b
    addl %r9d, 8(%rdi) # h[2] += c
    addl %r10d, 12(%rdi) # h[3] += d
    addl %r11d, 16(%rdi) # h[4] += e

    # restore callee-saved registers
    movq -32(%rbp), %r15
    movq -24(%rbp), %r14
    movq -16(%rbp), %r13
    movq -8(%rbp), %r12

    # epilogue
    movq %rbp, %rsp
    popq %rbp

    ret
