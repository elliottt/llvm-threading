#ifndef __thread_h
#define __thread_h

#ifdef __cplusplus
extern "C" {
#endif

extern void init_threading();

typedef void(*task)(void *);
typedef int stack_size;

extern void create_thread(task, void*, stack_size);

#ifdef __cplusplus
}
#endif

#endif /* __thread_h */
