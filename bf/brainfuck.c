#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>

#define TAPE_SIZE 30000

typedef int32_t cell_t;

void brainfuck(char *program) {
    printf("Program to run: %s\n", program);

    cell_t *mem = calloc(TAPE_SIZE, sizeof(cell_t));
    cell_t *ptr = &mem[0];

    char *command = &program[0];
    while(*command != '\0') {
	switch(*command) {
	    case '>':
		++ptr;
		break;
	    case '<':
		--ptr;
		break;
	    case '+':
		++(*ptr);
		break;
	    case '-':
		--(*ptr);
		break;
	    case '.':
		printf("%c", *ptr);
		break;
	    case ',':
		scanf("%c", ptr);
		break;
	    case '[':
		if(!(*ptr)) {
		    int depth = 1;
		    while(depth) {
			++command;
			if(*command == '[')
			    ++depth;
			if(*command == ']')
			    --depth;
		    }
		}
		break;
	    case ']':
		if(*ptr) {
		    int depth = 1;
		    while(depth) {
			--command;
			if(*command == '[')
			    --depth;
			if(*command == ']')
			    ++depth;
		    }
		}
		break;
	}
	++command;
    }

    printf("\n");

    return;
}
