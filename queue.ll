;
; A simple linked-list module that implements a basic queue.
;

%ListNode = type { %ListNode*, i8* }
%List     = type { %ListNode*, %ListNode* }

declare void @llvm.memset.p0i8.i32(i8* nocapture, i8, i32, i32, i1)
declare i8*  @malloc(i32)
declare void @free(i8*)

define %List* @newQueue()
{
    %fkptr  = getelementptr %List* null, i32 1
    %szlist = ptrtoint %List* %fkptr to i32
    %ptr    = call i8* @malloc(i32 %szlist)
    call void @llvm.memset.p0i8.i32(i8* %ptr, i8 0, i32 %szlist, i32 1, i1 0)
    %retptr = bitcast i8* %ptr to %List*
    ret %List* %retptr
}

define void @freeQueue(%List* %ptr)
{
    ; should probably not leak if non-empty, but ...
    %i8ptr = bitcast %List* %ptr to i8*
    call void @free(i8* %i8ptr)
    ret void
}

define void @enqueue(%List* %ptr, i8* %val)
{
    ; allocate the new node
    %fkptr   = getelementptr %ListNode* null, i32 1
    %size    = ptrtoint %ListNode* %fkptr to i32
    %tempPtr = call i8* @malloc(i32 %size)
    %newNode = bitcast i8* %tempPtr to %ListNode*
    ; fill in the fields
    %nextPtr = getelementptr %ListNode* %newNode, i32 0, i32 0
    store %ListNode* null, %ListNode** %nextPtr
    %valPtr  = getelementptr %ListNode* %newNode, i32 0, i32 1
    store i8* %val, i8** %valPtr
    ; check to see if the list is empty
    %lastPtrP = getelementptr %List* %ptr, i32 0, i32 1
    %lastPtr  = load %ListNode** %lastPtrP
    %isEmpty  = icmp eq %ListNode* %lastPtr, null
    br i1 %isEmpty, label %empty, label %append

empty:
    store %ListNode* %newNode, %ListNode** %lastPtrP
    %firstPtrP = getelementptr %List* %ptr, i32 0, i32 0
    store %ListNode* %newNode, %ListNode** %firstPtrP
    ret void

append:
    %lnNextP = getelementptr %ListNode* %lastPtr, i32 0, i32 0
    store %ListNode* %newNode, %ListNode** %lnNextP
    store %ListNode* %newNode, %ListNode** %lastPtrP
    ret void
}

define i8* @dequeue(%List* %ptr)
{
    %isNull = icmp eq %List* %ptr, null
    br i1 %isNull, label %badList, label %goodList

badList:
    ret i8* null

goodList:
    %firstPtrP = getelementptr %List* %ptr, i32 0, i32 0
    %firstPtr  = load %ListNode** %firstPtrP
    %isEmpty   = icmp eq %ListNode* %firstPtr, null
    br i1 %isEmpty, label %empty, label %remove

empty:
    ret i8* null

remove:
    %retvalP   = getelementptr %ListNode* %firstPtr, i32 0, i32 1
    %nextPtrP  = getelementptr %ListNode* %firstPtr, i32 0, i32 0
    %retval    = load i8** %retvalP
    %nextPtr   = load %ListNode** %nextPtrP
    %nodei8    = bitcast %ListNode* %firstPtr to i8*
    %isOnly    = icmp eq %ListNode* %nextPtr, null
    ;call void @free(i8* %nodei8)
    br i1 %isOnly, label %singleItem, label %multItems

singleItem:
    %lastPtrP  = getelementptr %List* %ptr, i32 0, i32 1
    store %ListNode* null, %ListNode** %firstPtrP
    store %ListNode* null, %ListNode** %lastPtrP
    br label %done

multItems:
    store %ListNode* %nextPtr, %ListNode** %firstPtrP
    %nextnextP = getelementptr %ListNode* %nextPtr, i32 0, i32 0
    %nextnext  = load %ListNode** %nextnextP
    %isLast    = icmp eq %ListNode* %nextnext, null
    br i1 %isLast, label %updateLast, label %done

updateLast:
    %lastPtrP2  = getelementptr %List* %ptr, i32 0, i32 1
    store %ListNode* %nextPtr, %ListNode** %lastPtrP2
    br label %done

done:
    ret i8* %retval
}

define i64 @queueLength(%List* %ptr)
{
    %isBad = icmp eq %List* %ptr, null
    br i1 %isBad, label %badList, label %loopHeader

badList:
    ret i64 0

loopHeader:
    %firstPtrP = getelementptr %List* %ptr, i32 0, i32 0
    %firstPtr  = load %ListNode** %firstPtrP
    br label %loop

loop:
    %curval    = phi i64 [0, %loopHeader], [%nextval, %advance]
    %curnode   = phi %ListNode* [%firstPtr, %loopHeader], [%nextnode, %advance]
    %isNull    = icmp eq %ListNode* %curnode, null
    br i1 %isNull, label %done, label %advance

advance:
    %nextval   = add i64 %curval, 1
    %nextnodeP = getelementptr %ListNode* %curnode, i32 0, i32 0
    %nextnode  = load %ListNode** %nextnodeP
    br label %loop

done:
    ret i64 %curval
}
