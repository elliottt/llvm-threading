declare i8* @malloc(i32)
declare void @free(i8*)
declare void @llvm.memset.p0i8.i32(i8*, i8, i32, i32, i1)

%Stack      = type i8*
%Queue      = type opaque
%TCB        = type { %Stack, i8*, %Queue* }
%ChanWaiter = type { %TCB*, i8* }
%Channel    = type {
    i8      ; State: 0 open, 1 reader waiting, 2 writer waiting
  , %Queue* ; Invalid in open state
            ; Queue of %TCBs/pointers in reader waiting state
            ; Queue of %TCBs in writer waiting state
  }

declare %Queue* @newQueue()
declare void @enqueue(%Queue*, i8*)
declare i8* @dequeue(%Queue*)
declare i64 @queueLength(%Queue* %ptr)

define private void @enqueueTCB(%Queue* %queue, %TCB* %tcb)
{
    %tcbi8 = bitcast %TCB* %tcb to i8*
    call void @enqueue(%Queue* %queue, i8* %tcbi8)
    ret void
}

define private %TCB* @dequeueTCB(%Queue* %queue)
{
    %tcbi8 = call i8* @dequeue(%Queue* %queue)
    %res   = bitcast i8* %tcbi8 to %TCB*
    ret %TCB* %res
}

declare %Stack @llvm.stacksave()
declare void @llvm.stackrestore(%Stack)


define %TCB* @alloc_tcb() {
    ; allocate and zero out the structure
    %ptr_tcb = getelementptr %TCB* null, i32 1
    %sz_tcb  = ptrtoint %TCB* %ptr_tcb to i32
    %ptr     = call i8* @malloc(i32 %sz_tcb)
    call void @llvm.memset.p0i8.i32(i8* %ptr, i8 0, i32 %sz_tcb, i32 1, i1 0)
    ; initialize the join list
    %tcb     = bitcast i8* %ptr to %TCB*
    %jlist   = call %Queue* @newQueue()
    %jlptr   = getelementptr %TCB* %tcb, i32 0, i32 2
    store %Queue* %jlist, %Queue** %jlptr
    ; return the new TCB
    ret %TCB* %tcb
}

%task = type void(i8*)

@running_queue  = global %Queue* null
@current_thread = global %TCB* null
@original_stack = global %Stack null

; create the main running task, and global queues
define void @run_threaded_system(%task* %t, i8* %val, i32 %stackSize) naked
{
    %cur_s = call %Stack @llvm.stacksave()
    %queue = call %Queue* @newQueue()
    store %Queue* %queue, %Queue** @running_queue
    store %Stack %cur_s, %Stack* @original_stack
    call %TCB* @create_thread(%task* %t, i8* %val, i32 %stackSize)
    ret void ; don't think we can get here, but ...
}

define %TCB* @create_thread(%task* %t, i8* %val, i32 %stackSize) naked noreturn
{
    ; allocate the new thread object
    %tcb     = call %TCB* @alloc_tcb()
    %s       = call %Stack @malloc(i32 %stackSize)
    %top     = getelementptr %Stack %s, i32 %stackSize
    %topi    = ptrtoint %Stack %top to i64
    %topm8i  = sub i64 %topi, 8
    %topm8   = inttoptr i64 %topm8i to %Stack
    %tcbstt  = getelementptr %TCB* %tcb, i32 0, i32 0
    %tcbstb  = getelementptr %TCB* %tcb, i32 0, i32 1
    store i8* %topm8, %Stack* %tcbstt
    store i8* %s, i8** %tcbstb
    ; call into our helper (we will end up returning here)
    call void @create_thread2(%task* %t, i8* %val, %TCB* %tcb)
    ret %TCB* %tcb
}

define private void @create_thread2(%task* %t, i8* %val, %TCB* %tcb)
  noinline naked
{
    ; get the current thread object
    %cur_t   = load %TCB** @current_thread
    %isNull  = icmp eq %TCB* %cur_t, null
    br i1 %isNull, label %createNew, label %saveCurrent

saveCurrent:
    ; get the current stack and bang it into the structure
    %cur_s   = call %Stack @llvm.stacksave()
    %stackPP = getelementptr %TCB* %cur_t, i32 0, i32 0
    store %Stack %cur_s, %Stack* %stackPP
    ; add the current thread object to the running queue
    %queue   = load %Queue** @running_queue
    call void @enqueueTCB(%Queue* %queue, %TCB* %cur_t)
    ; there is no currently running thread!
    store %TCB* null, %TCB** @current_thread
    br label %createNew

createNew:
    ; create the new TCB and set it as the currently-running thread
    store %TCB* %tcb, %TCB** @current_thread
    ; "restore" the stack and call into the function we want
    %tcpstt = getelementptr %TCB* %tcb, i32 0, i32 0
    %stack  = load %Stack* %tcpstt
    call void @llvm.stackrestore(%Stack %stack)
    call void @start_thread(%task* %t, i8* %val)

    ; shouldn't get here
    unreachable
}

define private void @start_thread(%task* %t, i8* %data) naked noreturn
{
    ; run the body of the thread
    call void %t(i8* %data)
    ; hey, we're back. cool. find our join list.
    %cur_t   = load %TCB** @current_thread
    %jlptr   = getelementptr %TCB* %cur_t, i32 0, i32 2
    %jlist   = load %Queue** %jlptr
    %rlist   = load %Queue** @running_queue
    br label %unwindJoinList

unwindJoinList:
    %jthread = call %TCB* @dequeueTCB(%Queue* %jlist)
    %done    = icmp eq %TCB* %jthread, null
    br i1 %done, label %cleanup, label %moveAndLoop

moveAndLoop:
    call void @enqueueTCB(%Queue* %rlist, %TCB* %jthread)
    br label %unwindJoinList

cleanup:
    ; cleanup the current thread
    %cur     = load %TCB** @current_thread
    %curi8   = bitcast %TCB* %cur to i8*
    %stackP  = getelementptr %TCB* %cur, i32 0, i32 1
    %stack   = load %Stack* %stackP
    call void @free(i8* %stack)
    call void @free(i8* %curi8)
    store %TCB* null, %TCB** @current_thread
    call void @schedule()
    unreachable
}

;declare i32 @printf(i8* noalias nocapture, ...)
;@str = internal constant [21 x i8] c"Current thread = %p\0A\00"

define void @yield() naked
{
    ; get the current thread object
    %cur_t   = load %TCB** @current_thread
    ; get the current stack and bang it into the structure
    %cur_s   = call %Stack @llvm.stacksave()
    %stackPP = getelementptr %TCB* %cur_t, i32 0, i32 0
    store %Stack %cur_s, %Stack* %stackPP
    ; add the current thread object to the running queue
    %queue   = load %Queue** @running_queue
    call void @enqueueTCB(%Queue* %queue, %TCB* %cur_t)
    ; there is no currently running thread!
    store %TCB* null, %TCB** @current_thread
    call void @schedule()
    ret void
}

define private void @schedule() naked
{
    ; yank the next thread off the queue
    %queue  = load %Queue** @running_queue
    %next   = call %TCB* @dequeueTCB(%Queue* %queue)
    ; set it as the next thread
    store %TCB* %next, %TCB** @current_thread
    %nothr  = icmp eq %TCB* %next, null
    br i1 %nothr, label %emptyRunQueue, label %goodQueue

emptyRunQueue:
    %origst = load %Stack* @original_stack
    call void @llvm.stackrestore(%Stack %origst)
    ret void

goodQueue:
    ; restore its stack
    %stackP = getelementptr %TCB* %next, i32 0, i32 0
    %stack  = load %Stack* %stackP
    call void @llvm.stackrestore(%Stack %stack)
    ; return to its caller
    ret void
}

define %Channel* @create_channel()
{
    ; allocate and initialize the memory to zero
    %ptrChan = getelementptr %Channel* null, i32 1
    %szChan  = ptrtoint %Channel* %ptrChan to i32
    %ptr     = call i8* @malloc(i32 %szChan)
    call void @llvm.memset.p0i8.i32(i8* %ptr, i8 0, i32 %szChan, i32 1, i1 0)
    ; allocate the thread queue and set the pointer
    %retval  = bitcast i8* %ptr to %Channel*
    %qptr    = getelementptr %Channel* %retval, i32 0, i32 1
    %queue   = call %Queue* @newQueue()
    store %Queue* %queue, %Queue** %qptr
    ; return the appropriately-casted value
    ret %Channel* %retval
}

define private i8* @buildWaitStruct(%TCB* %cur_t, i8* %val)
{
    %ptr0    = getelementptr %ChanWaiter* null, i32 1
    %wsz     = ptrtoint %ChanWaiter* %ptr0 to i32
    %ptr1    = call i8* @malloc(i32 %wsz)
    %ptr2    = bitcast i8* %ptr1 to %ChanWaiter*
    %ptrTCB0 = getelementptr %ChanWaiter* %ptr2, i32 0, i32 0
    %ptrVal0 = getelementptr %ChanWaiter* %ptr2, i32 0, i32 1
    store %TCB* %cur_t, %TCB** %ptrTCB0
    store i8* %val, i8** %ptrVal0
    ret i8* %ptr1
}

define i32 @send_channel(%Channel* %chan, i8* %val)
{
    %ptrst = getelementptr %Channel* %chan, i32 0, i32 0
    %state = load i8* %ptrst
    switch i8 %state, label %bad_chan [ i8 0, label %no_one_around
                                        i8 1, label %reader_waiting
                                        i8 2, label %writer_waiting ]

no_one_around:
    store i8 2, i8* %ptrst ; update the state
    call void @addWaiterAndBlock(%Channel* %chan, i8* %val)
    ret i32 0

reader_waiting:
    ; grab the channel's wait queue
    %qptr  = getelementptr %Channel* %chan, i32 0, i32 1
    %queue = load %Queue** %qptr
    ; grab the first waiter from the queue
    %first = call i8* @dequeue(%Queue* %queue)
    %isBad = icmp eq i8* %first, null
    br i1 %isBad, label %bad_queue, label %good_queue

good_queue:
    ; OK, %first is non-null. Pull the value and the thread.
    %frstw  = bitcast i8* %first to %ChanWaiter*
    %frsttp = getelementptr %ChanWaiter* %frstw, i32 0, i32 0
    %frstvp = getelementptr %ChanWaiter* %frstw, i32 0, i32 1
    %thread = load %TCB** %frsttp
    %vali8  = load i8** %frstvp
    %valp   = bitcast i8* %vali8 to i8**
    ; Free the waiter structure
    call void @free(i8* %first)
    ; Add the blocked thread back to the wait queue
    %tqueue = load %Queue** @running_queue
    call void @enqueueTCB(%Queue* %tqueue, %TCB* %thread)
    ; Write the value to the out value and return
    store i8* %val, i8** %valp
    ; Is this the last reader waiting for us?
    %count  = call i64 @queueLength(%Queue* %queue)
    %empty  = icmp eq i64 %count, 0
    br i1 %empty, label %nowEmpty, label %allDone

nowEmpty:
    ; The queue went from reader waiting to empty, so update the state
    store i8 0, i8* %ptrst
    ret i32 0

allDone:
    ret i32 0

bad_queue:
    ret i32 -2

writer_waiting:
    call void @addWaiterAndBlock(%Channel* %chan, i8* %val)
    ret i32 0

bad_chan:
    ret i32 -1
}

define i32 @recv_channel(%Channel* %chan, i8** %valp)
{
    %ptrst = getelementptr %Channel* %chan, i32 0, i32 0
    %state = load i8* %ptrst
    switch i8 %state, label %bad_chan [ i8 0, label %no_one_around
                                        i8 1, label %reader_waiting
                                        i8 2, label %writer_waiting ]

no_one_around:
    store i8 1, i8* %ptrst ; update the state
    %valp2 = bitcast i8** %valp to i8*
    call void @addWaiterAndBlock(%Channel* %chan, i8* %valp2)
    ret i32 0

reader_waiting:
    %valp3 = bitcast i8** %valp to i8*
    call void @addWaiterAndBlock(%Channel* %chan, i8* %valp3)
    ret i32 0

writer_waiting:
    ; grab the channel's wait queue
    %qptr  = getelementptr %Channel* %chan, i32 0, i32 1
    %queue = load %Queue** %qptr
    ; grab the first waiter from the queue
    %first = call i8* @dequeue(%Queue* %queue)
    %isBad = icmp eq i8* %first, null
    br i1 %isBad, label %bad_queue, label %good_queue

good_queue:
    ; OK, %first is non-null. Pull the value and the thread.
    %frstw  = bitcast i8* %first to %ChanWaiter*
    %frsttp = getelementptr %ChanWaiter* %frstw, i32 0, i32 0
    %frstvp = getelementptr %ChanWaiter* %frstw, i32 0, i32 1
    %thread = load %TCB** %frsttp
    %val    = load i8** %frstvp
    ; Free the waiter structure
    call void @free(i8* %first)
    ; Add the blocked thread back to the wait queue
    %tqueue = load %Queue** @running_queue
    call void @enqueueTCB(%Queue* %tqueue, %TCB* %thread)
    ; Write the value to the out value and return
    store i8* %val, i8** %valp
    ; Is this the last writer waiting for us?
    %count  = call i64 @queueLength(%Queue* %queue)
    %empty  = icmp eq i64 %count, 0
    br i1 %empty, label %nowEmpty, label %allDone

nowEmpty:
    ; The queue went from writer waiting to empty, so update the state
    store i8 0, i8* %ptrst
    ret i32 0

allDone:
    ret i32 0

bad_queue:
    ret i32 -2

bad_chan:
    ret i32 -1
}

; this needs to be no-inline, so that when we return to the current thread
; when the receive or send happens, we "return" back to the main body of the
; calling function
define private void @addWaiterAndBlock(%Channel* %chan, i8* %val) noinline naked
{
    ; get the current thread object
    %cur_t   = load %TCB** @current_thread
    ; get the current stack and bang it into the structure
    %cur_s   = call %Stack @llvm.stacksave()
    %stackPP = getelementptr %TCB* %cur_t, i32 0, i32 0
    store %Stack %cur_s, %Stack* %stackPP
    ; Build a waiting structure
    %wstrct  = call i8* @buildWaitStruct(%TCB* %cur_t, i8* %val)
    ; Get the current wait queue and add ourselves to it
    %qptr  = getelementptr %Channel* %chan, i32 0, i32 1
    %queue = load %Queue** %qptr
    call void @enqueue(%Queue* %queue, i8* %wstrct)
    ; schedule the next action
    call void @schedule()
    ret void
}

define void @thread_join(%TCB* %thread) naked
{
    ; get the current thread object
    %cur_t  = load %TCB** @current_thread
    ; get the current stack and bang it into the structure
    %cur_s  = call %Stack @llvm.stacksave()
    %stackp = getelementptr %TCB* %cur_t, i32 0, i32 0
    store %Stack %cur_s, %Stack* %stackp
    ; there is no current thread!
    store %TCB* null, %TCB** @current_thread
    ; get the thread's join list and add the formerly-current thread to it
    %jlptr  = getelementptr %TCB* %thread, i32 0, i32 2
    %jlist  = load %Queue** %jlptr
    %tcbptr = bitcast %TCB* %cur_t to i8*
    call void @enqueue(%Queue* %jlist, i8* %tcbptr)
    ; and go to the next person
    call void @schedule()
    ret void
}
