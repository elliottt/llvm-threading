LLVM_AS     = llvm-as
LLASFLAGS   =
LLC         = llc
LLCFLAGS    =
AS          = as
ASFLAGS     = -g -c
CC          = gcc
CFLAGS      = -g -c -fomit-frame-pointer -fomit-frame-pointer -Iinclude/
LD          = gcc
LDFLAGS     = -g
GHC         = ghc
GHCFLAGS    = -package QuickCheck

include mk/build.mk

TEST_SOURCES = $(shell find tests -name 'test*hs' -or -name 'test*c')
TESTS        = $(patsubst %.hs,%.elf,$(patsubst %.c,%.elf,$(TEST_SOURCES)))
TEST_RUNNERS = $(sort $(patsubst %.elf,%,$(TESTS)))

all: $(TESTS)
	@for t in $(TEST_RUNNERS); do $(MAKE) -s $$t; done

tests/%: tests/%.elf
	@if [ -f $@.gold ]; then                \
	  export F=`mktemp` ;                   \
	  ./$< > $${F} ;                        \
	  if `cmp -s $${F} $@.gold`; then       \
	    echo "Test $@ PASSED" ;             \
	  else                                  \
	    echo "Test $@ FAILED" ;             \
	  fi ;                                  \
	  rm $${F} ;                            \
	else                                    \
	  ./$<;                                 \
	fi

tests: $(TESTS_ELFS)
	for test in $(TESTS); do $${test}; done

clean:
	rm -f *.o *.bc *.s *.elf tests/*.{o,bc,s,elf,hi}

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
