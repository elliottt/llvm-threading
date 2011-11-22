LLVM_AS     = llvm-as
LLASFLAGS   =
LLC         = llc
LLCFLAGS    =
AS          = as
ASFLAGS     = -g -c
CC          = gcc
CFLAGS      = -g -c -fomit-frame-pointer -fomit-frame-pointer -Iinclude/
LD          = gcc
LDFLAGS     = -g -lrt
GHC         = ghc
GHCFLAGS    = -package QuickCheck

LLVM_FILES  = queue.ll sorted_list.ll thread.ll time.ll
LLVM_OBJS   = $(patsubst %.ll,%.o,$(LLVM_FILES))

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
