#include <assert.h>
#include <stddef.h>
#include <stdio.h>

struct vector { int *arr; int len; int cap; };
extern struct vector *new_vector(int cap);
extern int get_element(struct vector *vec, int pos);
extern int push_element(struct vector *vec, int elem);
extern int pop_element(struct vector *vec);
extern void print_vector(struct vector *vec);
extern void free_vector(struct vector **vec);

int main(void) {
    struct vector *v = new_vector(2);
    assert(v != NULL);
    assert(push_element(v, 10) == 0);
    assert(push_element(v, 20) == 1);
    assert(push_element(v, 30) == 2); /* triggers growth */
    assert(get_element(v, 1) == 20);
    print_vector(v);
    assert(pop_element(v) == 30);
    free_vector(&v);
    assert(v == NULL);
    return 0;
}
