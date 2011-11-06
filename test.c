
#include <stdio.h>

#include "thread.h"

extern void *current_thread;

#define runTest(x)              \
{                               \
    while(1) {                  \
        printf("%li\n", x);     \
        yield();                \
    }                           \
}

void test(void *data) {
    while(1) {
        printf("%li\n", (long)data);
        yield();
    }
}

int main() {
    init_threading();
    printf("current-thread = %p\n", current_thread);
    create_thread(test, (void*)1, 1024);
    create_thread(test, (void*)2, 10240);
    test((void*)0);
    return 0;
}
