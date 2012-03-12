#ifndef __thread_h
#define __thread_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

typedef void(*task)(void *);
typedef uint64_t stack_size;

struct channel;
typedef struct channel channel;
typedef struct thread thread;

extern void run_threaded_system(task, void*, stack_size);

extern thread *create_thread(task, void*, stack_size);
extern void maybeYield();
extern void yield();
extern void sleep(uint64_t microseconds);
extern void thread_join(thread *);

extern channel *create_channel();
extern int send_channel(channel*, void *data);
extern int recv_channel(channel*, void **data);

#ifdef __cplusplus
}
#endif

#endif /* __thread_h */
