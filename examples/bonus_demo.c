#include <stdio.h>
extern void ave(char *src, char *dest, int n);
extern void switch_cases(char *src, char *dest);
extern void heavy(int number);
extern void flat_matrix(int *mat, int n);
int main(void) {
    char encoded[32], flipped[32];
    char text1[] = "ABC", text2[] = "AbC";
    int matrix[] = {1, 2, 3, 4};
    ave(text1, encoded, 1);
    switch_cases(text2, flipped);
    printf("Shifted: %s\nSwapped case: %s\n", encoded, flipped);
    heavy(0);
    flat_matrix(matrix, 2);
    return 0;
}
