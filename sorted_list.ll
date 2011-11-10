%Comparator = type i8(i8*, i8*)
%ListNode   = type { %ListNode*, i8* }
%List       = type { %ListNode*, %Comparator* }

declare i8*  @malloc(i32)
declare void @free(i8*)

define %List* @newSortedList(%Comparator* %comp)
{
    %ptr_sl = getelementptr %List* null, i32 1
    %sizesl = ptrtoint %List* %ptr_sl to i32
    %ptr    = call i8* @malloc(i32 %sizesl)
    %list   = bitcast i8* %ptr to %List*

    %ptrhd  = getelementptr %List* %list, i32 0, i32 0
    %ptrcmp = getelementptr %List* %list, i32 0, i32 1

    store %ListNode* null, %ListNode** %ptrhd
    store %Comparator* %comp, %Comparator** %ptrcmp

    ret %List* %list
}

define %List* @newSortedListLT()
{
    %retval = call %List* @newSortedList(%Comparator* @lessThan)
    ret %List* %retval
}

define i8 @lessThan(i8* %first, i8* %second)
{
    %compare  = icmp ult i8* %first, %second
    br i1 %compare, label %lesst, label %greaterequal
lesst:
    ret i8 -1
greaterequal:
    %compare2 = icmp eq i8* %first, %second
    br i1 %compare2, label %equal, label %greater
equal:
    ret i8 0
greater:
    ret i8 1
}

define void @addItem(%List* %list, i8* %item)
{
start:
    ; allocate and set up most of the new node
    %sznd   = getelementptr %ListNode* null, i32 1
    %szndi  = ptrtoint %ListNode* %sznd to i32
    %nodep  = call i8* @malloc(i32 %szndi)
    %node   = bitcast i8* %nodep to %ListNode*
    %valp   = getelementptr %ListNode* %node, i32 0, i32 1
    store i8* %item, i8** %valp
    ; get the head of the list and the comparator
    %ptrls  = getelementptr %List* %list, i32 0, i32 0
    %pcomp  = getelementptr %List* %list, i32 0, i32 1
    %list2  = load %ListNode** %ptrls
    br label %loop

loop:
    ; start with a prev pointer (optimized to just be the memory location of
    ; prev->next) and the current item to check.
    %updatePtr = phi %ListNode** [ %ptrls, %start ], [ %newupdate, %tryAgain]
    %curNode   = phi %ListNode*  [ %list2, %start ], [ %newlist, %tryAgain]
    ; check for null
    %atEnd     = icmp eq %ListNode* %curNode, null
    br i1 %atEnd, label %insertNode, label %checkNode

checkNode:
    ; see if this current value is less than the current node
    %curDataP  = getelementptr %ListNode* %curNode, i32 0, i32 1
    %curData   = load i8** %curDataP
    %comp      = load %Comparator** %pcomp
    %compVal   = call i8 %comp(i8* %item, i8* %curData)
    %putHere   = icmp slt i8 %compVal, 0
    br i1 %putHere, label %insertNode, label %tryAgain

tryAgain:
    %newupdate = getelementptr %ListNode* %curNode, i32 0, i32 0
    %newlist   = load %ListNode** %newupdate
    br label %loop

insertNode:
    %nextp     = getelementptr %ListNode* %node, i32 0, i32 0
    store %ListNode* %curNode, %ListNode** %nextp
    store %ListNode* %node, %ListNode** %updatePtr
    ret void
}

define i8* @getItem(%List* %list)
{
    %isBad = icmp eq %List* %list, null
    br i1 %isBad, label %badList, label %checkEmpty

checkEmpty:
    %listp = getelementptr %List* %list, i32 0, i32 0
    %ls    = load %ListNode** %listp
    %isEmp = icmp eq %ListNode* %ls, null
    br i1 %isEmp, label %badList, label %getFirst

getFirst:
    %nextp = getelementptr %ListNode* %ls, i32 0, i32 0
    %valp  = getelementptr %ListNode* %ls, i32 0, i32 1
    %next  = load %ListNode** %nextp
    store %ListNode* %next, %ListNode** %listp
    %val   = load i8** %valp
    %nodep = bitcast %ListNode* %ls to i8*
    call void @free(i8* %nodep)
    ret i8* %val

badList:
    ret i8* null
}

define i64 @getLength(%List* %list)
{
    %isBad = icmp eq %List* %list, null
    br i1 %isBad, label %badList, label %startLoop

badList:
    ret i64 0

startLoop:
    %headp = getelementptr %List* %list, i32 0, i32 0
    %head  = load %ListNode** %headp
    br label %loop

loop:
    %curv  = phi i64 [0, %startLoop], [%nextv, %again]
    %curn  = phi %ListNode* [%head, %startLoop], [%nextn, %again]
    %atend = icmp eq %ListNode* %curn, null
    br i1 %atend, label %done, label %again

again:
    %nextp = getelementptr %ListNode* %curn, i32 0, i32 0
    %nextv = add i64 %curv, 1
    %nextn = load %ListNode** %nextp
    br label %loop

done:
    ret i64 %curv
}

define void @freeList(%List* %list)
{
    %listp = bitcast %List* %list to i8*
    call void @free(i8* %listp)
    ret void
}
