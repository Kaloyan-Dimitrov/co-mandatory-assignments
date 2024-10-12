#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define TAPE_SIZE 30000

enum BF_OP {
    END = 0,
    INC_PC,
    DEC_PC,
    INC,
    DEC,
    READ,
    WRITE,
    JMPZ,
    JMPNZ,
    ZERO,
    MOV_PC,
    MOV
};
typedef struct bf_instr {
    enum BF_OP op;
    size_t val;
} bf_instr_t;

typedef struct stack {
    size_t size;
    size_t *data;
    size_t *top;
} stack_t;
void init(stack_t *self) {
    self->size = 512;
    self->data = calloc(self->size, sizeof(size_t));
    self->top = self->data;
}
void push(stack_t *self, size_t val) {
    if(self->top - self->data == self->size) {
	self->size *= 2;
	self->data = realloc(self->data, self->size * sizeof(size_t));
    }
    *(self->top) = val;
    ++self->top;
}
size_t pop(stack_t *self) {
    if(self->top == self->data)
	return -1;
    --self->top;
    return *self->top;
}

bf_instr_t* optimize_loop(bf_instr_t *prog, size_t prog_len, size_t loop_start) {
    bf_instr_t *new_instr = calloc(128, sizeof(bf_instr_t));
}

bf_instr_t* compile(const char *code) {
    size_t code_len = strlen(code);
    
    bf_instr_t *prog = calloc(code_len + 1, sizeof(bf_instr_t));
    bf_instr_t *next_instr = &prog[0];

    stack_t jmps;
    init(&jmps);

    for(size_t i = 0; i < code_len; ++i) {
	size_t c = 1;
	switch(code[i]) {
	    case '>':
		while(code[i + c] == '>')
		    ++c;
		*next_instr = (bf_instr_t) { .op = INC_PC, .val = c }; 
		++next_instr;
		break;
	    case '<':
		while(code[i + c] == '<')
		    ++c;
		*next_instr = (bf_instr_t) { .op = DEC_PC, .val = c }; 
		++next_instr;
		break;
	    case '+':
		while(code[i + c] == '+')
		    ++c;
		*next_instr = (bf_instr_t) { .op = INC, .val = c }; 
		++next_instr;
		break;
	    case '-':
		while(code[i + c] == '-')
		    ++c;
		*next_instr = (bf_instr_t) { .op = DEC, .val = c }; 
		++next_instr;
		break;
	    case ',':
		while(code[i + c] == ',')
		    ++c;
		*next_instr = (bf_instr_t) { .op = READ, .val = c }; 
		++next_instr;
		break;
	    case '.':
		while(code[i + c] == '.')
		    ++c;
		*next_instr = (bf_instr_t) { .op = WRITE, .val = c }; 
		++next_instr;
		break;
	    case '[':
		push(&jmps, next_instr - prog);
		*next_instr = (bf_instr_t) { .op = JMPZ, .val = 0 };
		++next_instr;
		break;
	    case ']':
		size_t jmpz = pop(&jmps);
		prog[jmpz].val = next_instr - prog;
		*next_instr = (bf_instr_t) { .op = JMPNZ, .val = jmpz };
		++next_instr;
		break;
	}
	i += c - 1;
    }

    *next_instr = (bf_instr_t) { .op = END, .val = 0 };

    size_t prog_len = next_instr - prog - 1;
    prog = optimize_loops(prog, prog_len);
    
    return prog;
}

typedef int8_t cell_t;

void brainfuck(const char *code) {
    printf("Program to run: %s\n", code);

    cell_t *mem = calloc(TAPE_SIZE, sizeof(cell_t));
    cell_t *ptr = &mem[0];

    bf_instr_t *program = compile(code);
    size_t pc = 0;

    while(program[pc].op != END) {
	switch(program[pc].op) {
	    case INC_PC:
		ptr += program[pc].val;
		break;
	    case DEC_PC:
		ptr -= program[pc].val;
		break;
	    case INC:
		*ptr += program[pc].val;
		break;
	    case DEC:
		*ptr -= program[pc].val;
		break;
	    case READ:
		for(size_t i = 0; i < program[pc].val; ++i)
		    scanf("%c", ptr);
		break;
	    case WRITE:
		for(size_t i = 0; i < program[pc].val; ++i)
		    printf("%c", *ptr);
		break;
	    case JMPZ:
		if(!(*ptr))
		    pc = program[pc].val;
		break;
	    case JMPNZ:
		if(*ptr)
		    pc = program[pc].val;
		break;
	}
	++pc;
    }

    printf("\n");

    return;
}
