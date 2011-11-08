#ifndef __thread_h
#define __thread_h

#ifdef __cplusplus
extern "C" {
#endif

extern void init_threading();

typedef void(*task)(void *);
typedef int stack_size;

struct channel;
typedef struct channel channel;

extern void create_thread(task, void*, stack_size);
extern void yield();

extern channel *create_channel();
extern void send_channel(channel*, void *data);
extern void *recv_channel(channel*);

#ifdef __cplusplus
}
#endif

#endif /* __thread_h */
