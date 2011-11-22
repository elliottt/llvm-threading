#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>

int64_t getTicks();

void doSomething()
{
    usleep(500000); // not part of our system, but handy
}

int main(int argc, char argv)
{
  int64_t a, b, c;

  a = getTicks();
  doSomething();
  b = getTicks();
  doSomething();
  c = getTicks();

  if((a <= b) && (b <= c)) {
    printf("PASSED!\n");
    return 0;
  } else {
    printf("FAILED! (%li, %li, %li)\n", a, b, c);
    return -1;
  }
}
