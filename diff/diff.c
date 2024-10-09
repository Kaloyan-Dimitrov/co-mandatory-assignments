#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>

#define LINE_LENGTH 128

size_t count_lines(char **lines) {
    if(lines == NULL)
	return 0;

    size_t count = 0;
    while(lines[count] != NULL)
	++count;

    return count;
}

char** compute_lcs(char **x, size_t x_len, char **y, size_t y_len) {
    if(!x_len || !y_len)
	return NULL;

    char **x_prim = malloc(x_len);
    for(size_t i = 0; i < x_len - 1; ++i) {
	x_prim[i] = malloc(LINE_LENGTH);
	strcpy(x_prim[i], x[i]);
    }
    x_prim[x_len - 1] = NULL;

    char **y_prim = malloc(y_len);
    for(size_t i = 0; i < y_len - 1; ++i) {
	y_prim[i] = malloc(LINE_LENGTH);
	strcpy(y_prim[i], y[i]);
    }
    y_prim[y_len - 1] = NULL;

    if(!strcmp(x[x_len - 1], y[y_len - 1])) {
	char **lcs_prim = compute_lcs(x_prim, x_len - 1, y_prim, y_len - 1);
	if(!lcs_prim)
	    return lcs_prim;

	char **lcs_prim_cat = malloc(count_lines(lcs_prim) + 2);
	for(size_t i = 0; i < x_len - 1; ++i)
	    strcpy(lcs_prim_cat[i], lcs_prim[i]);
	strcpy(lcs_prim_cat[count_lines(lcs_prim)], x[x_len - 1]);
	lcs_prim_cat[count_lines(lcs_prim) + 1] = NULL;

	return lcs_prim_cat;
    }

    char **x_prim_lcs = compute_lcs(x_prim, x_len - 1, y, y_len);
    char **y_prim_lcs = compute_lcs(x, x_len , y_prim, y_len - 1);

    return count_lines(x_prim_lcs) > count_lines(y_prim_lcs) ? x_prim_lcs : y_prim_lcs;
}

void diff(char **lhs, size_t lhs_len, char **rhs, size_t rhs_len, bool ignore_case, bool ignore_blank) {
    char **lcs = compute_lcs(lhs, lhs_len, rhs, rhs_len);

    size_t lcs_len = count_lines(lcs);

    size_t lhs_p = 0;
    size_t rhs_p = 0;
    size_t lcs_p = 0;
    while(lcs_p < lcs_len) {
	size_t old_lhs_p = lhs_p;
	while(lhs_p < lhs_len && strcmp(lhs[lhs_p], lcs[lcs_p])) ++lhs_p;
	size_t old_rhs_p = rhs_p;
	while(rhs_p < rhs_len && strcmp(rhs[rhs_p], lcs[lcs_p])) ++rhs_p;

	if(old_lhs_p != lhs_p && old_rhs_p != rhs_p) {
	    if(old_lhs_p - lhs_p == 1)
		printf("\x1b[36m%zu%c%zu\x1b[0m\n", lhs_p, 'c', rhs_p);
	    else
		printf("\x1b[36m%zu,%zu%c%zu,%zu\x1b[0m\n", old_lhs_p + 1, lhs_p, 'c', old_rhs_p + 1, rhs_p);
	    while(old_lhs_p < lhs_p)
		printf("\x1b[31m< %s\x1b[0m", lhs[old_lhs_p++]);
	    printf("---\n");
	    while(old_rhs_p < rhs_p)
		printf("\x1b[32m> %s\x1b[0m", rhs[old_rhs_p++]);
	}
	if(old_lhs_p != lhs_p) {
	    if(old_lhs_p - lhs_p == 1)
		printf("\x1b[36m%zu%c%zu\x1b[0m\n", lhs_p, 'd', rhs_p);
	    else
		printf("\x1b[36m%zu,%zu%c%zu\x1b[0m\n", old_lhs_p + 1, lhs_p, 'd', rhs_p);
	    while(old_lhs_p < lhs_p)
		printf("\x1b[31m< %s\x1b[0m", lhs[old_lhs_p++]);
	}
	if(old_rhs_p != rhs_p) {
	    if(old_lhs_p - lhs_p == 1)
		printf("\x1b[36m%zu%c%zu\x1b[0m\n", lhs_p, 'a', rhs_p);
	    else
		printf("\x1b[36m%zu%c%zu,%zu\x1b[0m\n", lhs_p, 'a', old_rhs_p + 1, rhs_p);
	    while(old_rhs_p < rhs_p)
		printf("\x1b[32m> %s\x1b[0m", rhs[old_rhs_p++]);
	}
	++lcs_p;
	++lhs_p;
	++rhs_p;
    }
    if(lhs_p != lhs_len) {
	if(lhs_len - lhs_p == 1)
	    printf("\x1b[36m%zu%c%zu\x1b[0m\n", lhs_p + 1, 'd', rhs_p);
	else
	    printf("\x1b[36m%zu,%zu%c%zu\x1b[0m\n", lhs_p + 1, lhs_len, 'd', rhs_p);
	while(lhs_p < lhs_len)
	    printf("\x1b[31m< %s\x1b[0m", lhs[lhs_p++]);
    }
    if(rhs_p != rhs_len) {
	if(rhs_len - rhs_p == 1)
	    printf("\x1b[36m%zu%c%zu\x1b[0m\n", lhs_p, 'a', rhs_p + 1);
	else
	    printf("\x1b[36m%zu%c%zu,%zu\x1b[0m\n", lhs_p, 'a', rhs_p + 1, rhs_len);
	while(rhs_p < rhs_len)
	    printf("\x1b[32m> %s\x1b[0m", rhs[rhs_p++]);
    }
}

void exit_with_usage() {
    printf("Usage: ./diff file1 file2 [-i] [-B]\n");
    exit(1);
}

size_t read_file(FILE *fp, char ***out) {
    char *buf = malloc(LINE_LENGTH);
    size_t lines = 128;
    *out = malloc(lines);

    size_t idx = 0;
    while(fgets(buf, LINE_LENGTH, fp)) {
	(*out)[idx] = malloc(LINE_LENGTH);
	strcpy((*out)[idx], buf);
	++idx;
	if(idx == lines - 1) {
	    lines *= 2;
	    *out = realloc(*out, lines);
	}
    }
    (*out)[idx] = NULL;

    return idx;
}

int main(int argc, char *argv[]) {
    if(argc < 3)
	exit_with_usage();

    FILE *file1 = fopen(argv[1], "r");
    FILE *file2 = fopen(argv[2], "r");
    bool ignore_case = false;
    bool ignore_blank = false;

    for(size_t i = 3; i < argc; ++i) {
	if(argv[i][0] == '-') {
	    if(argv[i][1] == 'i') ignore_case = true;
	    else if(argv[i][1] == 'B') ignore_blank = true;
	    else exit_with_usage();
	} else {
	    exit_with_usage();
	}
    }

    char **lhs;
    size_t lhs_len = read_file(file1, &lhs);
    char **rhs;
    size_t rhs_len = read_file(file2, &rhs);
    diff(lhs, lhs_len, rhs, rhs_len, ignore_case, ignore_blank);
 
    return 0;
}
