#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
extern int check_langford(int *sequence, int len);
extern int **generate_langford_sequences(int n, int *seq_num);
int main(void) {
    int example[] = { 2, 3, 1, 2, 1, 3 };
    assert(check_langford(example, 6) == 1);
    int count = 0;
    int **sequences = generate_langford_sequences(3, &count);
    assert(count == 2);
    assert(sequences != NULL);
    for (int i = 0; i < count; ++i) {
        for (int j = 0; j < 6; ++j)
            printf("%d%s", sequences[i][j], j == 5 ? "\n" : " ");
        free(sequences[i]);
    }
    free(sequences);
    return 0;
}
