#include <stdio.h>

// Message:
// 0x00 0x00 | 0x00 0x00 0x00 0x00 | 0x00 | 0x00
void decode(long *block) {
    long next_address = ((*block) & 0x0000FFFFFFFF0000) >> 4;
    long count = ((*block) & 0x000000000000FF00) >> 2;
    long character = (*block) & 0x00000000000000FF;

    while(count--)
	putc(character, stdout);

    decode((long*) next_address);
}

int main() {
    decode(0x0);

    return 0;
}
