
#include <stdio.h>

#include "thread.h"

extern void *current_thread;

void test(void *data) {
    while(1) {
        printf("%li\n", (long)data);
        yield();
    }
}

int main() {
    long i = 0;

    init_threading();
    for(i = 1; i < 10; i++)
      create_thread(test, (void*)i, 10240);
    test((void*)0);
    return 0;
}
