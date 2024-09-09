#include <stdio.h>

static long *base_message = 0x0;

// Message:
// 0x00 0x00 | 0x00 0x00 0x00 0x00 | 0x00 | 0x00
void decode(long *block) {
    long next_address = ((*block) & 0x0000FFFFFFFF0000) >> 32;
    long count = ((*block) & 0x000000000000FF00) >> 16;
    long character = (*block) & 0x00000000000000FF;

    while(count--)
	putc(character, stdout);

    if(!next_address)
	return;
    decode(base_message + (next_address * 8));
}

int main() {
    decode(base_message);

    return 0;
}
