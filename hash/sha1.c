#include <stdint.h>

uint32_t lrot(uint32_t val, uint32_t bits) {
    return (val << bits) | (val >> (32 - bits));
}

void message_schedule(uint32_t w[80]) {
    for(uint8_t i = 16; i < 80; ++i)
	w[i] = lrot(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16], 1);
}

void sha1_chunk(uint32_t h[5], uint32_t w[80]) {
    message_schedule(w);

    uint32_t a = h[0];
    uint32_t b = h[1];
    uint32_t c = h[2];
    uint32_t d = h[3];
    uint32_t e = h[4];

    for(uint8_t i = 0; i < 80; ++i) {
	uint32_t f, k;
	if (i < 20) {
	    f = (b & c) | ((~b) & d);
	    k = 0x5A827999;
	} else if (i < 40) {
	    f = b ^ c ^ d;
	    k = 0x6ED9EBA1;
	} else if (i < 60) {
	    f = (b & c) | (b & d) | (c & d);
	    k = 0x8F1BBCDC;
	} else {
	    f = b ^ c ^ d;
	    k = 0xCA62C1D6;
	}

	uint32_t temp = lrot(a, 5) + f + e + k + w[i];
	e = d;
	d = c;
	c = lrot(b, 30);
	b = a;
	a = temp;
    }

    h[0] += a;
    h[1] += b;
    h[2] += c;
    h[3] += d;
    h[4] += e;
}
