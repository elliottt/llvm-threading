#include <stdio.h>
#include <sys/types.h>
#include "thread.h"

int64_t getTicks();

void initialThread(void *dead)
{
  int64_t a, b, c, delay;

  delay = microsecondsToTicks(500000);
  a = getTicks();
  sleep(500000);
  b = getTicks();
  sleep(500000);
  c = getTicks();

  if(a + delay <= b)
    printf("PASSED PART ONE\n");
  else
    printf("FAILED PART ONE (%lli + %lli > %lli)\n", a, delay, b);

  if(b + delay <= c)
    printf("PASSED PART TWO\n");
  else
    printf("FAILED PART TWO (%lli + %lli > %lli)\n", b, delay, c);
}

int main(int argc, char argv)
{
    run_threaded_system(initialThread, 0, 10240);
    return 0;
}
