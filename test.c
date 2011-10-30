
#include <stdio.h>

#include "thread.h"

void test(void *data) {
	printf("task!\n");

	return;
}

int main() {
	init_threading();

	printf("main thread\n");

	create_thread(test, NULL, 1024);
	printf("after create_thread\n");

	return 0;
}
