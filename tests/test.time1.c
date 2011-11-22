#include <stdio.h>
#include <sys/types.h>
#include <sys/time.h>

int64_t microsecondsToTicks(int64_t);
int64_t ticksToMicroseconds(int64_t);
int64_t secondsToTocks(int64_t);
int64_t timespecToTicks(struct timespec *tv);
void    ticksToTimespec(int64_t, struct timespec *);
int64_t getTicks();

int main(int argc, char **argv)
{
  struct timespec tm1, tm2;

  printf("64 microseconds = %lli ticks (should be 1)\n",
         microsecondsToTicks(64));
  printf("3 seconds is %lli ticks (should be 46875)\n",
         secondsToTicks(3));
  printf("10 ticks = %lli microseconds (should be 640)\n",
         ticksToMicroseconds(10));

  tm1.tv_sec = 3; tm1.tv_nsec = 500000000;
  printf("3.5 seconds (%lli, %lli) = %lli ticks (should be 54687)\n",
         tm1.tv_sec, tm1.tv_nsec, timespecToTicks(&tm1));
  ticksToTimespec(54687, &tm2);
  printf("Reversed, 54687 ticks = (%lli, %lli)\n", tm2.tv_sec, tm2.tv_nsec);

  return 0;
}
