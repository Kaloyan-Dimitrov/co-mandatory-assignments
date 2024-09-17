#include <sys/mman.h>

char* itoa(int n) {
    char *str;
    mmap(str, 64, PROT_READ | PROT_WRITE, MAP_PRIVATE
    for(int i = 0; str[i] != '\0'; ++i) {
	rev_str
    }
}

int len(char *str) {
    int result = 0;
    while(*(str++) != 0)
	++result;
    return result;
}

void print_str(char *str) {
    int i = 0;
    while(str[i++] != '\0') {
	putchar(str[i]);
    }
}

void my_printf(char *format_string, ...) {
    va_list args;
    va_start(args, format_string);

    for(int i = 0; format_string[i] != '\0'; ++i) {
	if(format_string[i] == '%') {
	    int len;
	    switch(format_string[++i]) {
		case 'd':
		    itoa(va_arg(args, int));
		    print_str(itoa_str);
		    break;
		case 'u':
		    itoa(va_arg(args, unsigned int));
		    print_str(itoa_str);
		    break;
		case 's':
		    printf("%s", va_arg(args, char*));
		    break;
		default:
		    putchar('%');
		    putchar(format_string[i]);
		    break;
	    }
	} else {
	    putchar(format_string[i]);
	}
    }
}

int main() {
    my_printf("My name is %s. I think I’ll get a %u for my exam. What does %r do? And %%?\n", "Piet", 10);

    return 0;
}
