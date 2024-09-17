#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>

char* lcs(char *x, char *y) {
    size_t x_len = strlen(x);
    size_t y_len = strlen(y);
    if(!(x_len && y_len))
	return "";

    char *x_prim = malloc(y_len + 1);
    strcpy(x_prim, x);
    x_prim[x_len - 1] = '\0';

    char *y_prim = malloc(y_len + 1);
    strcpy(y_prim, y);
    y_prim[y_len - 1] = '\0';

    if(x[x_len - 1] == y[y_len - 1]) {
	char *lcs_prim = lcs(x_prim, y_prim);

	char *lcs_prim_cat = malloc(strlen(lcs_prim) + 2);
	strcpy(lcs_prim_cat, lcs_prim);
	lcs_prim_cat[strlen(lcs_prim)] = x[x_len - 1];
	lcs_prim_cat[strlen(lcs_prim) + 1] = '\0';

	return lcs_prim_cat;
    }

    char *x_prim_lcs = lcs(x_prim, y);
    char *y_prim_lcs = lcs(x, y_prim);

    return strlen(x_prim_lcs) > strlen(y_prim_lcs) ? x_prim_lcs : y_prim_lcs;
}

void diff(char *lhs, char *rhs, bool ignore_case, bool ignore_blank) {
    char *lhs_rhs_lcs = lcs(lhs, rhs);
    size_t lcs_len = strlen(lhs_rhs_lcs);

    char *lhs_d = malloc(lcs_len + 1);
    size_t lcs_p = 0;
    size_t lhs_p = 0;
    for(size_t i = 0; i < strlen(lhs); ++i) {
	if(lhs[i] != lhs_rhs_lcs[lcs_p]) {
	    lhs_d[lhs_p++] = lhs[i];
	}
	++lcs_p;
	--i;
    }
    char *rhs_a = malloc(lcs_len + 1);
    size_t rhs_p = 0;
    for(size_t i = 0; i < strlen(rhs); ++i) {
	if(rhs[i] != lhs_rhs_lcs[rhs_p])
	    rhs_a[rhs_p++] = rhs[i];
    }

    printf("%s\n%s\n%s\n", lcs(lhs, rhs), lhs_d, rhs_a);
}

int main(int argc, char *argv[]) {
    if(argc < 3)
	printf("Usage: ./diff text_left text_right [-i] [-B]\n");

    char *lhs = malloc(strlen(argv[1]) + 1);
    strcpy(lhs, argv[1]);
    char *rhs = malloc(strlen(argv[2]) + 1);
    strcpy(rhs, argv[2]);
    bool ignore_case = false;
    bool ignore_blank = false;

    diff(lhs, rhs, ignore_case, ignore_blank);
    
    return 0;
}
