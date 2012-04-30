#include <stdio.h>
#include <sys/types.h>
#include <thread.h>

int usleep(long);

struct time {
  int64_t tv_sec;
  int32_t tv_nsec;
};

void doSomething()
{
    usleep(500000); // not part of our system, but handy
}

int main(int argc, char **argv)
{
  TimeSpec a, b, c;
  long long diff1, diff2;

  system_time(&a);
  doSomething();
  system_time(&b);
  doSomething();
  system_time(&c);

  diff1 = compareTime(&a, &b);
  diff2 = compareTime(&b, &c);

  if((diff1 <= 0) && (diff2 <= 0)) {
    printf("PASSED!\n");
    return 0;
  } else {
    printf("FAILED! (%li:%i, %li:%i, %li:%i)\n",
           a.ts_secs, a.ts_usecs, b.ts_secs, b.ts_usecs, c.ts_secs, c.ts_usecs);
    return -1;
  }
}
