#include <stdio.h>

int ipow(int base, int exp) {
    int total = 1;

    while(exp--)
	total *= base;

    return total;
}

int main() {
    printf("%d\n", ipow(3, 4));
}
