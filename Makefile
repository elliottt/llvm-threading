
LLCFLAGS ?=

%.bc: %.ll
	llvm-as -o $@ $<

%.s: %.bc
	llc $(LLCFLAGS) -o $@ $<


all: test

clean:
	$(RM) thread.{bc,s,o} test.o test

.PRECIOUS: thread.s

test: ASFLAGS := -g
test: CFLAGS := -g
test: test.o thread.o
	$(CC) -o $@ $^
