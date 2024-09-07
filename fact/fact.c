#include <stdio.h>

int fact(int n) {
    if(n == 1)
	return 1;
    return fact(n - 1) * n;
}

int main() {
    int n = -1;
    while (n <= 0)
	scanf("%d", &n);

    printf("%d\n", fact(n));

    return 0;
}
