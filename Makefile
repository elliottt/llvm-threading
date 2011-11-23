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
CPP         = cpp
CPPFLAGS    = -Iinclude/

LLVM_FILES  = queue.lla sorted_list.lla thread.lla time.lla
LLVM_FILESP = $(foreach f,$(LLVM_FILES),src/$(f))
LLVM_OBJS   = $(patsubst %.lla,%.o,$(LLVM_FILESP))

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
	rm -f *.o *.bc *.s *.elf tests/*.{o,bc,s,elf,hi} src/*.{o,bc,s,elf,hi,ll}

src/queue.ll: include/queue.llh include/system.llh include/llvm.llh
src/sorted_list.ll: include/sorted_list.llh include/system.llh include/llvm.llh
src/time.ll: include/time.llh include/system.llh
src/thread.ll: include/system.llh include/llvm.llh include/queue.llh
