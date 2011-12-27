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
GHCFLAGS    =
CPP         = cpp
CPPFLAGS    = -Iinclude/

LLVM_FILES  = queue.lla sorted_list.lla thread.lla time.lla
LLVM_FILESP = $(foreach f,$(LLVM_FILES),src/$(f))
LLVM_OBJS   = $(patsubst %.lla,%.o,$(LLVM_FILESP))

include mk/build.mk

TEST_SOURCES = $(shell find tests -name 'test*hs' -or -name 'test*c')
TESTS        = $(patsubst %.hs,%.elf,$(patsubst %.c,%.elf,$(TEST_SOURCES)))
TEST_RUNNERS = $(sort $(patsubst %.elf,%,$(TESTS)))

all: $(TESTS) test
	./test

test: Test.hs $(LLVM_OBJS)
	$(call cmd,hs_to_elf)

clean:
	rm -f *.{o,bc,hi,s,elf} tests/*.{o,bc,s,elf,hi} src/*.{o,bc,s,elf,hi,ll}

src/queue.ll: include/queue.llh include/system.llh include/llvm.llh
src/sorted_list.ll: include/sorted_list.llh include/system.llh include/llvm.llh
src/time.ll: include/time.llh include/system.llh
src/thread.ll: include/system.llh include/llvm.llh include/queue.llh
src/thread.ll: include/sorted_list.llh include/time.llh
src/thread.ll: include/thread.h
