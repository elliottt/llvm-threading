#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>

struct time {
  int64_t tv_sec;
  int32_t tv_nsec;
};

struct time *system_time(struct time*);
long long compareTime(struct time*, struct time*);
struct time *addTime(struct time*, struct time*, struct time*);
void         system_sleepFor(struct time*);

int main(int argc, char **argv)
{
  struct time a, b, c, delay, ad, bd;
  long long compare;

  delay.tv_sec = 0;
  delay.tv_nsec = 5000000;

  system_time(&a);
  system_sleepFor(&delay);
  system_time(&b);
  system_sleepFor(&delay);
  system_time(&c);

  addTime(&a, &delay, &ad);
  addTime(&b, &delay, &bd);

  compare = compareTime(&ad, &b);
  if(compare <= 0)
    printf("PASSED PART ONE\n");
  else
    printf("FAILED PART ONE (%li:%i + %li:%i = %li:%i > %li:%i)\n",
           a.tv_sec, a.tv_nsec, delay.tv_sec, delay.tv_nsec,
           ad.tv_sec, ad.tv_nsec, b.tv_sec, b.tv_nsec);

  compare = compareTime(&bd, &c);
  if(compare <= 0)
    printf("PASSED PART TWO\n");
  else
    printf("FAILED PART TWO (%li:%i + %li:%i = %li:%i > %li:%i)\n",
           b.tv_sec, b.tv_nsec, delay.tv_sec, delay.tv_nsec,
           bd.tv_sec, bd.tv_nsec, c.tv_sec, c.tv_nsec);

  return 0;
}

