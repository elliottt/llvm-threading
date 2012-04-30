#include <stdio.h>
#include <sys/types.h>
#include <thread.h>

extern int usleep(long);

void doSomething()
{
    usleep(1000000); // not part of our system, but handy
}

void initialThread(void *dead)
{
  TimeSpec a, b, c;

  system_time(&a);
  doSomething();
  system_time(&b);
  doSomething();
  system_time(&c);

  if(compareTime(&a, &b) + compareTime(&b, &c) == -2) {
    printf("PASSED!\n");
  } else {
    printf("FAILED! (%li:%i, %li:%i, %li:%i, %li, %li)\n", 
           a.ts_secs, a.ts_usecs, b.ts_secs, b.ts_usecs, c.ts_secs, c.ts_usecs,
           compareTime(&a, &b), compareTime(&b, &c));
  }
}

int main(int argc, char **argv)
{
    run_threaded_system(initialThread, 0, 10240);
    return 0;
}
