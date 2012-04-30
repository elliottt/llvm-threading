#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

struct time {
  int64_t tv_sec;
  int32_t tv_nsec;
};

struct time *system_time(struct time *);
struct time *addTime(struct time*, struct time*, struct time*);
int          compareTime(struct time*, struct time*);

int main(int argc, char **argv)
{
  struct time tm1, tm2, tm3;

  system_time(&tm1);
  tm2.tv_sec = 2;
  tm2.tv_nsec = 0;
  addTime(&tm1, &tm2, &tm3);

  do {
    system_time(&tm1);
  } while(compareTime(&tm1, &tm3) < 0);
  printf("Done!\n");

  return 0;
}
