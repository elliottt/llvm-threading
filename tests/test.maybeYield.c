#include <stdio.h>
#include "thread.h"

double fact(int x)
{
    double res = 1;
    int i;

    for(i = 1; i <= x; i++)
        res *= (double)i;

    return res;
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
      create_thread(test, (void*)i, 102400);
    test((void*)0);
}

int main(int argc, char **argv)
{
    run_threaded_system(initThread, (void*)0, 102400);
    return 0;
}
