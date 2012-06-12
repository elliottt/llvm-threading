#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <sys/time.h>

struct tspec {
  uint64_t sec;
  uint32_t nsec;
};

extern int system_run_every(struct tspec *ts, void (*callback)());

void handler()
{
  printf("TICK!\n");
}

int main(int argc, char **argv)
{
  struct tspec ts = { 0, 20000000 };
  int res;

  res = system_run_every(&ts, handler);
  printf("res = %i\n", res);
  if(res == 0) {
    struct timeval cur, goal;

    gettimeofday(&cur, NULL);
    goal.tv_sec = cur.tv_sec + 5;

    while(cur.tv_sec < goal.tv_sec)
      gettimeofday(&cur, NULL);
  }

  return res;
}
