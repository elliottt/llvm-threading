
#include <stdio.h>

#include "thread.h"

void test(void *data) {
	printf("2\n");
	yield();
	printf("3\n");

	return;
}

int main() {
	init_threading();

	printf("1\n");

	create_thread(test, NULL, 1024);
	printf("4\n");
	yield();
	printf("5\n");

	return 0;
}
