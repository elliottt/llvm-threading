
LLCFLAGS ?=

%.bc: %.ll
	llvm-as -o $@ $<

%.s: %.bc
	llc $(LLCFLAGS) -o $@ $<


all: test

clean:
	$(RM) thread.{bc,s,o} queue.{bc,s,o} test.o test

QCqueue: queue.o QuickCheck/QC_DataStructures.hs
	ghc -o QCqueue QuickCheck/QC_DataStructures.hs queue.o

runQCqueue: QCqueue
	./QCqueue

.PRECIOUS: thread.s

thread.o: queue.o

test: ASFLAGS := -g
test: CFLAGS := -g
test: test.o thread.o queue.o
	$(CC) -o $@ $^
