
#include <stdio.h>

#include "thread.h"

extern void *current_thread;

void test(void *data) {
    int i;

    for(i = 0; i < 10; i++) {
        printf("%li\n", (long)data);
        yield();
    }
}

void initThread(void *dead)
{
    long i = 0;

    for(i = 1; i < 10; i++)
      create_thread(test, (void*)i, 10240);
    test((void*)0);
}

int main(int argc, char **argv)
{
    run_threaded_system(initThread, (void*)0, 10240);
    return 0;
}
