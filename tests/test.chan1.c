#include <stdlib.h>
#include <stdio.h>
#include <thread.h>

channel *chan;

void sender(void *dead)
{
  int err;

  if((err = send_channel(chan, (void*)0x2357)) != 0) {
    printf("Failure to send! (%i)\n", err);
  } else {
    printf("Sent on channel.\n");
  }
}

void receiver(void *dead)
{
  void *val;
  int err;

  if((err = recv_channel(chan, &val)) != 0) {
    printf("Failure to receive! (%i)\n", err);
  } else {
    printf("Received value 0x%lx\n", (unsigned long)val);
  }
}

int main(int argc, char **argv)
{
    init_threading();
    chan = create_channel();
    create_thread(sender, (void*)0, 10240);
    receiver(0);
    return 0;
}
