
#include <stdio.h>

#include "thread.h"

extern void *current_thread;

double fact(int x)
{
    double res = 1;
    int i;

    for(i = 1; i <= x; i++)
        res *= (double)i;
}

void test(void *data) {
    unsigned long threadNum = (unsigned long)data;
    int i;

    for(i = 0; i < 10000; i++) {
        printf("Thread #%ld: %g\n", threadNum, fact(i));
        maybeYield();
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
