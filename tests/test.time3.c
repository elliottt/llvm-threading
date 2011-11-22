#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>

int64_t getTicks();
void sleepFor(int64_t);

int main(int argc, char **argv)
{
  int64_t a, b, c, delay;

  delay = microsecondsToTicks(500000);
  a = getTicks();
  sleepFor(delay);
  b = getTicks();
  sleepFor(delay);
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

