#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <sys/time.h>

struct tspec {
  uint64_t sec;
  uint32_t nsec;
};

extern int set_timer_handler(void (*callback)());
extern long long int start_thread_timer(struct tspec*);

void handler()
{
  printf("TICK!\n");
}

int main(int argc, char **argv)
{
  struct tspec ts = { 0, 20000000 };
  int res;

  res = set_timer_handler(&handler);
  if(res != 0) {
    printf("set alarm fail: %d\n", res);
    exit(res);
  }
  res = start_thread_timer(&ts);
  if(res >= 0) {
    struct timeval cur, goal;

    printf("Got a timer!\n");
    gettimeofday(&cur, NULL);
    goal.tv_sec = cur.tv_sec + 5;

    while(cur.tv_sec < goal.tv_sec)
      gettimeofday(&cur, NULL);
  }

  return res > 0 ? 0 : res;
}
