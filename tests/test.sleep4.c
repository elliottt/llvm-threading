#include <stdio.h>
#include <sys/types.h>
#include <thread.h>

void test1(void *dead) {
  sleep(1000000);
  printf("test1\n");
}

void test2(void *dead) {
  sleep(2000000);
  printf("test2\n");
}

void test3(void *dead) {
  sleep(3000000);
  printf("test3\n");
}

void initialThread(void *dead)
{
  create_thread(test3, (void*)0, 10240);
  create_thread(test2, (void*)0, 10240);
  create_thread(test1, (void*)0, 10240);
}

int main(int argc, char **argv)
{
    run_threaded_system(initialThread, 0, 10240);
    return 0;
}
