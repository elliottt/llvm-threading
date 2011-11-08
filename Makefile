LLVM_AS     = llvm-as
LLASFLAGS   =
LLC         = llc
LLCFLAGS    =
AS          = as
ASFLAGS     = -g -c
CC          = gcc
CFLAGS      = -g -c -fomit-frame-pointer -fomit-frame-pointer
LD          = gcc
LDFLAGS     =

TARGET      = test
TARGET_OBJS = queue.o thread.o test.o

include mk/build.mk

clean:
	rm -f *.o *.bc *.s $(TARGET)

#LLCFLAGS ?=
#
#%.bc: %.ll
#	llvm-as -o $@ $<
#
#%.s: %.bc
#	llc $(LLCFLAGS) -o $@ $<
#
#
#all: test
#
#clean:
#	$(RM) thread.{bc,s,o} queue.{bc,s,o} test.o test
#
#QCqueue: queue.o QuickCheck/QC_DataStructures.hs
#	ghc -o QCqueue QuickCheck/QC_DataStructures.hs queue.o
#
#runQCqueue: QCqueue
#	./QCqueue
#
#.PRECIOUS: thread.s
#
#thread.o: queue.o
#
#test.o: CFLAGS := -g -mno-red-zone -fomit-frame-pointer
#test: ASFLAGS := -g
#test: CFLAGS := -g
#test: test.o thread.o queue.o
#	$(CC) -o $@ -mno-red-zone $^
