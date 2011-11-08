
#include <stdio.h>

#include "thread.h"

extern void *current_thread;

void test1(void *data) {
    int i;

    for(i = 0; i < 10; i++) {
        printf("%li\n", (long)1);
        yield();
    }
}

void test2(void *data) {
    int i;

    for(i = 0; i < 10; i++) {
        printf("%li\n", (long)2);
        yield();
    }
}

int main(int argc, char **argv)
{
    long i = 0;

    init_threading();
    create_thread(test1, (void*)0, 10240);
    test2((void*)1);
    return 0;
}
