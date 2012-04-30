#include <stdlib.h>
#include <stdio.h>
#include <thread.h>

void sender(channel *outchan)
{
  unsigned long err, i;

  for(i = 0; i < 100; i++) {
      if((err = send_channel(outchan, (void*)i)) != 0) {
        printf("Failure to send! (%li)\n", err);
      }
  }
}

typedef struct dual_channel {
  channel *in, *out;
} dual_channel;

void transfer(dual_channel *chans)
{
    unsigned long err, i, val;

    for(i = 0; i < 100; i++) {
        if((err = recv_channel(chans->in, (void**)&val)) != 0) {
          printf("Failure to receive! (%li)\n", err);
        } else {
          if((err = send_channel(chans->out, (void*)val)) != 0) {
            printf("Failure to send! (%li)\n", err);
          }
        }
    }
}

void receiver(channel *inchan)
{
  unsigned long err, i;
  void *val;

  for(i = 0; i < 100; i++) {
      if((err = recv_channel(inchan, &val)) != 0) {
        printf("Failure to receive! (%li)\n", err);
      } else {
        printf("Received value %ld\n", (unsigned long)val);
      }
      if((unsigned long)val != i) printf("Bad value!\n");
  }
}

void initThread(void *dead)
{
    channel *prev = create_channel();
    int i;

    create_thread((task)sender,   (void*)prev, 10240);
    for(i = 0; i < 10; i++) {
        dual_channel *dual = malloc(sizeof(dual_channel));
        dual->in  = prev;
        dual->out = prev = create_channel();
        create_thread((task)transfer, (void*)dual, 10240);
    }
    create_thread((task)receiver, (void*)prev, 10240);
}

int main(int argc, char **argv)
{
    run_threaded_system(initThread, (void*)0, 10240);
    return 0;
}
