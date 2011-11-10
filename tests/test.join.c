#include <stdlib.h>
#include <stdio.h>
#include <thread.h>

void tester(void *dead)
{
    yield();
    printf("Back from tester\n");
}

void initialThread(void *dead)
{
    thread *thr = create_thread(tester, (void*)0, 10240);
    thread_join(thr);
    printf("Back from join.\n");
}

int main(int argc, char **argv)
{
    run_threaded_system(initialThread, 0, 10240);
    return 0;
}
