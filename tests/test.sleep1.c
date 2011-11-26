#include <stdio.h>
#include <sys/types.h>
#include "thread.h"

int64_t getTicks();

void doSomething()
{
    sleep(500000); // not part of our system, but handy
}

void initialThread(void *dead)
{
  int64_t a, b, c;

  a = getTicks();
  doSomething();
  b = getTicks();
  doSomething();
  c = getTicks();

  if((a <= b) && (b <= c)) {
    printf("PASSED!\n");
  } else {
    printf("FAILED! (%li, %li, %li)\n", a, b, c);
  }
}

int main(int argc, char argv)
{
    run_threaded_system(initialThread, 0, 10240);
    return 0;
}
