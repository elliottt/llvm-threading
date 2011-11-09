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
extern int send_channel(channel*, void *data);
extern int recv_channel(channel*, void **data);

#ifdef __cplusplus
}
#endif

#endif /* __thread_h */
