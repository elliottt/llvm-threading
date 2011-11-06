declare i8* @malloc(i32)
declare void @free(i8*)
declare void @llvm.memset.p0i8.i32(i8*, i8, i32, i32, i1)

%Stack = type i8*
%Queue = type opaque
%TCB = type { %Stack }

declare %Queue* @newQueue()
declare void @enqueue(%Queue*, i8*)
declare i8* @dequeue(%Queue*)

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
	%ptr_tcb = getelementptr %TCB* null, i32 1
	%sz_tcb  = ptrtoint %TCB* %ptr_tcb to i32

	%ptr = call i8* @malloc(i32 %sz_tcb)
	call void @llvm.memset.p0i8.i32(i8* %ptr, i8 0, i32 %sz_tcb,
			i32 1, i1 0)

	%tcb = bitcast i8* %ptr to %TCB*
	ret %TCB* %tcb
}

define private void @set_stack(%TCB* %tcb, %Stack %s) alwaysinline {
	%ptr_stack = getelementptr %TCB* %tcb, i32 0, i32 0
	store %Stack %s, %Stack* %ptr_stack
	ret void
}

define private %Stack @get_stack(%TCB* %tcb) alwaysinline {
	%ptr_stack = getelementptr %TCB* %tcb, i32 0, i32 0
	%s = load %Stack* %ptr_stack
	ret %Stack %s
}

%task = type void(i8*)

@running_queue  = global %Queue* null
@current_thread = global %TCB* null

; create the main running task, and global queues
define void @init_threading() {
    %tcb   = call %TCB* @alloc_tcb()
    %queue = call %Queue* @newQueue()

    store %Queue* %queue, %Queue** @running_queue
    store %TCB* %tcb, %TCB** @current_thread

    ret void
}

define void @create_thread(%task* %t, i8* %val, i32 %stackSize) naked noreturn {
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
    ; create the new TCB and set it as the currently-running thread
    %tcb     = call %TCB* @alloc_tcb()
    %s       = call %Stack @malloc(i32 %stackSize)
    %top     = getelementptr %Stack %s, i32 %stackSize
    %topi    = ptrtoint %Stack %top to i64
    %topm8i  = sub i64 %topi, 8
    %topm8   = inttoptr i64 %topm8i to %Stack
    store %TCB* %tcb, %TCB** @current_thread
    ; "restore" the stack and call into the function we want
    call void @llvm.stackrestore(%Stack %topm8)
    call void @start_thread(%task* %t, i8* %val)

    ; shouldn't get here
    unreachable
}

define private void @start_thread(%task* %t, i8* %data) naked noreturn {
    ; run the body of the thread
    call void %t(i8* %data)
    ; cleanup the current thread
    %cur     = load %TCB** @current_thread
    %curi8   = bitcast %TCB* %cur to i8*
    %stackP  = getelementptr %TCB* %cur, i32 0, i32 0
    %stack   = load %Stack* %stackP
    call void @free(i8* %stack)
    call void @free(i8* %curi8)
    store %TCB* null, %TCB** @current_thread
    ; yank the next thread off the queue
    %queue  = load %Queue** @running_queue
    %next   = call %TCB* @dequeueTCB(%Queue* %queue)
    ; set it as the next thread
    store %TCB* %next, %TCB** @current_thread
    ; restore its stack
    %stackR = getelementptr %TCB* %next, i32 0, i32 0
    %stack2 = load %Stack* %stackR
    call void @llvm.stackrestore(%Stack %stack2)
    ; return to its caller
    ret void
}

declare i32 @printf(i8* noalias nocapture, ...)
@str = internal constant [21 x i8] c"Current thread = %p\0A\00"

define void @yield() naked {
    ; get the current thread object
    %cur_t   = load %TCB** @current_thread
    %caststr = getelementptr [21 x i8]* @str, i32 0, i32 0
    %meh = call i32 (i8*, ...)* @printf(i8* %caststr, %TCB* %cur_t)
    ; get the current stack and bang it into the structure
    %cur_s   = call %Stack @llvm.stacksave()
    %stackPP = getelementptr %TCB* %cur_t, i32 0, i32 0
    store %Stack %cur_s, %Stack* %stackPP
    ; add the current thread object to the running queue
    %queue   = load %Queue** @running_queue
    call void @enqueueTCB(%Queue* %queue, %TCB* %cur_t)
    ; there is no currently running thread!
    store %TCB* null, %TCB** @current_thread
    ; yank the next thread off the queue
    %next   = call %TCB* @dequeueTCB(%Queue* %queue)
    ; set it as the next thread
    store %TCB* %next, %TCB** @current_thread
    ; restore its stack
    %stackP = getelementptr %TCB* %next, i32 0, i32 0
    %stack  = load %Stack* %stackP
    call void @llvm.stackrestore(%Stack %stack)
    ; return to its caller
    ret void
}
