
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

void test3(void *data) {
    int i;

    for(i = 0; i < 10; i++) {
        printf("%li\n", (long)3);
        yield();
    }
}

void initThread(void *dead)
{
    create_thread(test1, (void*)0, 10240);
    create_thread(test2, (void*)0, 10240);
    test3((void*)1);
}

int main(int argc, char **argv)
{
    run_threaded_system(initThread, (void*)0, 10240);
    return 0;
}
