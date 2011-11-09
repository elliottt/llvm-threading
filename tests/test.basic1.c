
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

void initialThread(void *dead)
{
    long i = 0;

    create_thread(test1, (void*)0, 10240);
    test2((void*)1);
}

int main(int argc, char **argv)
{
    run_threaded_system(initialThread, 0, 10240);
    return 0;
}
