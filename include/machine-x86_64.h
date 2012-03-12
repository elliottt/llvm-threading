#ifndef MACHINE_X86_64_H
#define MACHINE_X86_64_H

#ifdef HAVE_MACHINE_ABI_INCLUDE
#error "Multiple machine ABIs included."
#endif

#define SAVE_CALLEE_SAVE_REGISTERS() \
    tail call void asm sideeffect "push %rbp ; push %rbx ; push %r12 ; push %r13 ; push %r14 ; push %r15",""()

#define RESTORE_CALLEE_SAVE_REGISTERS() \
    tail call void asm sideeffect "pop %r15 ; pop %r14 ; pop %r13 ; pop %r12 ; pop %rbx ; pop %rbp",""()

#endif
