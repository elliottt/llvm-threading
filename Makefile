LLVM_AS     = llvm-as
LLASFLAGS   =
LLC         = llc
LLCFLAGS    = -O2
CC          = clang
CFLAGS      = -g -c -Iinclude/ -Wall -Werror -Wno-format
LD          = gcc
LDFLAGS     =
GHC         = ghc
GHCFLAGS    = -ignore-package QuickCheck-2.5
CPP         = clang -E
CPPFLAGS    = -Iinclude/ -nostdinc
AS          = as
ASFLAGS     = -g

ifeq ("$(shell uname -s)","Linux")
ASFLAGS  += -c
LDFLAGS  += -lrt
CPPFLAGS += -DLINUX
SYSTEM    = Linux
endif

ifeq ("$(shell uname -s)","Darwin")
CPPFLAGS += -DDARWIN
SYSTEM    = Darwin
endif

ifeq ("$(POSIX)","y")
CPPFLAGS += -DPOSIX
SYSTEM    = POSIX
endif

LLVM_FILES  = queue.lla sorted_list.lla thread.lla system.lla time.lla
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
	rm -f include/machine-abi.h src/system.lla

src/queue.ll: include/queue.llh include/system.llh include/llvm.llh
src/queue.ll: include/time.llh
src/sorted_list.ll: include/sorted_list.llh include/system.llh include/llvm.llh
src/time.ll: include/time.llh include/system.llh
src/thread.ll: include/system.llh include/llvm.llh include/queue.llh
src/thread.ll: include/sorted_list.llh include/time.llh
src/thread.ll: include/thread.h
src/thread.ll: include/machine-abi.h

include/machine-abi.h: include/machine-$(shell uname -m).h
	ln -sf $(<F) $@

src/system.lla: src/system-$(SYSTEM).lla
	ln -sf $(<F) $@

