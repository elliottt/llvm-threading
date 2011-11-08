
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

int main(int argc, char **argv)
{
    long i = 0;

    init_threading();
    for(i = 1; i < 10; i++)
      create_thread(test, (void*)i, 10240);
    test((void*)0);
    return 0;
}
