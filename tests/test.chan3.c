#include <stdlib.h>
#include <stdio.h>
#include <thread.h>

channel *chan;

void sender(void *dead)
{
  unsigned long err, i;

  for(i = 0; i < 10; i++) {
      if((err = send_channel(chan, (void*)i)) != 0) {
        printf("Failure to send! (%i)\n", err);
      }
  }
}

void receiver(void *dead)
{
  void *val;
  unsigned long err, i;

  for(i = 0; i < 10; i++) {
      if((err = recv_channel(chan, &val)) != 0) {
        printf("Failure to receive! (%i)\n", err);
      } else {
        printf("Received value 0x%lx\n", (unsigned long)val);
      }
      if((unsigned long)val != i) printf("Bad value! (%i!=%i)\n",val,i);
  }
}

void initThread(void *dead)
{
    chan = create_channel();
    create_thread(receiver, (void*)0, 10240);
    sender(0);
    yield();
}

int main(int argc, char **argv)
{
    run_threaded_system(initThread, (void*)0, 10240);
    return 0;
}
