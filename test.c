
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

void test0(void *data) { runTest(0); }
void test1(void *data) { runTest(1); }
void test2(void *data) { runTest(2); }

int main() {
    init_threading();
    printf("current-thread = %p\n", current_thread);
    create_thread(test1, (void*)1, 1024);
    create_thread(test2, (void*)2, 10240);
    test0((void*)0);
    return 0;
}
