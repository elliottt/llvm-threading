

declare i8* @malloc(i32)
declare void @free(i8*)
declare void @llvm.memset.p0i8.i32(i8*, i8, i32, i32, i1)

%stack = type i8*

declare %stack @llvm.stacksave()
declare void @llvm.stackrestore(%stack)

%tcb = type { %stack }

define %tcb* @alloc_tcb() {
	%ptr_tcb = getelementptr %tcb* null, i32 1
	%sz_tcb  = ptrtoint %tcb* %ptr_tcb to i32

	%ptr = call i8* @malloc(i32 %sz_tcb)
	call void @llvm.memset.p0i8.i32(i8* %ptr, i8 0, i32 %sz_tcb,
			i32 1, i1 0)

	%tcb = bitcast i8* %ptr to %tcb*
	ret %tcb* %tcb
}

define private void @set_stack(%tcb* %tcb, %stack %s) alwaysinline {
	%ptr_stack = getelementptr %tcb* %tcb, i32 0, i32 0
	store %stack %s, %stack* %ptr_stack
	ret void
}

define private %stack @get_stack(%tcb* %tcb) alwaysinline {
	%ptr_stack = getelementptr %tcb* %tcb, i32 0, i32 0
	%s = load %stack* %ptr_stack
	ret %stack %s
}


%tcb_node = type { %tcb*, %tcb_queue, %tcb_queue }

%tcb_queue = type %tcb_node*

; allocate a tcb queue node, and fill it with zeros.  set the tcb element to the
; pointer provided
define %tcb_queue @alloc_node(%tcb* %tcb) {
	%ptr_q = getelementptr %tcb_queue null, i32 1
	%sz_q  = ptrtoint %tcb_queue %ptr_q to i32

	%ptr = call i8* @malloc(i32 %sz_q)
	call void @llvm.memset.p0i8.i32(i8* %ptr, i8 0, i32 %sz_q, i32 1, i1 0)

	%q = bitcast i8* %ptr to %tcb_queue
	call void @set_tcb(%tcb_queue %q, %tcb* %tcb)

	ret %tcb_queue %q
}

; set the tcb field of a tcb queue
define private void @set_tcb(%tcb_queue %q, %tcb* %p) alwaysinline {
	%ptr_tcb = getelementptr %tcb_queue %q, i32 0, i32 0
	store %tcb* %p, %tcb** %ptr_tcb
	ret void
}

define private %tcb* @get_tcb(%tcb_queue %q) alwaysinline {
	%ptr_tcb = getelementptr %tcb_queue %q, i32 0, i32 0
	%tcb     = load %tcb** %ptr_tcb
	ret %tcb* %tcb
}

define private void @set_next(%tcb_queue %q, %tcb_queue %n) alwaysinline {
	%ptr_next = getelementptr %tcb_queue %q, i32 0, i32 1
	store %tcb_queue %n, %tcb_queue* %ptr_next
	ret void
}

define private %tcb_queue @get_next(%tcb_queue %q) alwaysinline {
	%ptr  = getelementptr %tcb_queue %q, i32 0, i32 1
	%prev = load %tcb_queue* %ptr
	ret %tcb_queue %prev
}

define private void @set_prev(%tcb_queue %q, %tcb_queue %n) alwaysinline {
	%ptr_prev = getelementptr %tcb_queue %q, i32 0, i32 2
	store %tcb_queue %n, %tcb_queue* %ptr_prev
	ret void
}

define private %tcb_queue @get_prev(%tcb_queue %q) alwaysinline {
	%ptr  = getelementptr %tcb_queue %q, i32 0, i32 2
	%prev = load %tcb_queue* %ptr
	ret %tcb_queue %prev
}

define void @enqueue_front(%tcb_queue* %q, %tcb_queue %n) {
	; put the node on the tail of the queue
	call void @enqueue(%tcb_queue* %q, %tcb_queue %n)

	; set the new head
	store %tcb_queue %n, %tcb_queue* %q

	ret void
}

define void @enqueue(%tcb_queue* %q, %tcb_queue %n) {
	%head = load %tcb_queue* %q

	%isEmpty = icmp eq %tcb_queue %head, null
	br i1 %isEmpty, label %empty, label %append

empty:
	; the queue is empty, so loop it
	call void @set_next(%tcb_queue %n, %tcb_queue %n)
	call void @set_prev(%tcb_queue %n, %tcb_queue %n)
	store %tcb_queue %n, %tcb_queue* %q
	ret void

append:
	; the queue is non-empty, so add this node off of the tail
	%tail = call %tcb_queue @get_prev(%tcb_queue %head)

	; fixup the current and tail
	call void @set_next(%tcb_queue %tail, %tcb_queue %n)
	call void @set_prev(%tcb_queue %head, %tcb_queue %n)

	; fixup %n
	call void @set_next(%tcb_queue %n, %tcb_queue %head)
	call void @set_prev(%tcb_queue %n, %tcb_queue %tail)

	ret void
}

define %tcb_queue @dequeue(%tcb_queue* %q) {
	%head = load %tcb_queue* %q
	%isEmpty = icmp eq %tcb_queue %head, null
	br i1 %isEmpty, label %empty, label %dequeue

empty:
	; the queue is already empty, so return null
	ret %tcb_queue null

dequeue:
	; the queue is not empty.  first check to see if it is a singleton
	%tail = call %tcb_queue @get_prev(%tcb_queue %head)
	%isSingleton = icmp eq %tcb_queue %head, %tail
	br i1 %isSingleton, label %singleton, label %cons

singleton:
	; as there is only one element in the queue, pull it out, clear its
	; pointers and return
	call void @set_next(%tcb_queue %head, %tcb_queue null)
	call void @set_prev(%tcb_queue %head, %tcb_queue null)
	store %tcb_queue null, %tcb_queue* %q
	ret %tcb_queue %head

cons:
	; take the head off of the queue and return it, setting the next node to
	; the new value of %q
	%next = call %tcb_queue @get_next(%tcb_queue %head)
	call void @set_next(%tcb_queue %tail, %tcb_queue %next)
	call void @set_prev(%tcb_queue %next, %tcb_queue %tail)
	store %tcb_queue %next, %tcb_queue* %q
	call void @set_next(%tcb_queue %head, %tcb_queue null)
	call void @set_prev(%tcb_queue %head, %tcb_queue null)
	ret %tcb_queue %head
}


%task = type void(i8*)

@running_queue = global %tcb_queue null

; create the main running task, and global queues
define void @init_threading() {
	%tcb  = call %tcb* @alloc_tcb()
	%node = call %tcb_queue @alloc_node(%tcb* %tcb)

	call void @set_stack(%tcb* %tcb, %stack null)
	call void @set_tcb(%tcb_queue %node, %tcb* %tcb)
	call void @enqueue(%tcb_queue* @running_queue, %tcb_queue %node)

	ret void
}

define void @create_thread(%task* %t, i8* %data, i32 %stackSize)
	naked noreturn {
	; save the current state, and push it to the end of the running queue
	%cur_s   = call %stack @llvm.stacksave()
	%cur_n   = call %tcb_queue @dequeue(%tcb_queue* @running_queue)
	%cur_tcb = call %tcb* @get_tcb(%tcb_queue %cur_n)
	call void @set_stack(%tcb* %cur_tcb, %stack %cur_s)
	call void @enqueue(%tcb_queue* @running_queue, %tcb_queue %cur_n)

	; create the new tcb, and set it as the running task
	%tcb  = call %tcb* @alloc_tcb()
	%node = call %tcb_queue @alloc_node(%tcb* %tcb)
	%s    = call %stack @malloc(i32 %stackSize)

	%top = getelementptr %stack %s, i32 %stackSize

	call void @set_stack(%tcb* %tcb, %stack %top)
	call void @set_tcb(%tcb_queue %node, %tcb* %tcb)
	call void @enqueue_front(%tcb_queue* @running_queue, %tcb_queue %node)

	; set the new stack, and call the task function
	call void @llvm.stackrestore(%stack %top)
	call void @start_thread(%task* %t, i8* %data)

	unreachable
}

define void @start_thread(%task* %t, i8* %data) naked {
	; run the body of the thread
	call void %t(i8* %data)

	; cleanup the current thread
	%cur         = call %tcb_queue @dequeue(%tcb_queue* @running_queue)
	%cur_tcb     = call %tcb* @get_tcb(%tcb_queue %cur)
	%cur_ptr     = bitcast %tcb_queue %cur to i8*
	%cur_tcb_ptr = bitcast %tcb* %cur_tcb to i8*
	call void @free(i8* %cur_ptr)
	call void @free(i8* %cur_tcb_ptr)

	; the thread has exited, force a reschedule
	%next = load %tcb_queue* @running_queue

	; pull the stack pointer out of the tcb
	%tcb = call %tcb* @get_tcb(%tcb_queue %next)
	%s   = call %stack @get_stack(%tcb* %tcb)

	; restore the stack, and jump back into the original task
	call void @llvm.stackrestore(%stack %s)
	ret void
}

define void @yield() naked {
	; save the current context
	%cur     = call %tcb_queue @dequeue(%tcb_queue* @running_queue)
	%cur_s   = call %stack @llvm.stacksave()
	%cur_tcb = call %tcb* @get_tcb(%tcb_queue %cur)
	call void @set_stack(%tcb* %cur_tcb, %stack %cur_s)

	; dequeue the next task, queue the current one
	call void @enqueue(%tcb_queue* @running_queue, %tcb_queue %cur)

	; load the next task
	%next = load %tcb_queue* @running_queue
	%tcb  = call %tcb* @get_tcb(%tcb_queue %next)
	%s    = call %stack @get_stack(%tcb* %tcb)

	; restore the stack and jump back into the task
	call void @llvm.stackrestore(%stack %s)
	ret void
}
