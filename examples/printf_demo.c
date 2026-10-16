#include <stdio.h>
extern int my_printf(const char *format, ...);
int main(void) {
    int n = my_printf("Hello, %s! Value=%lu%c\n", "Assembly", 42UL, '!');
    if (n < 1) return 1;
    return 0;
}
