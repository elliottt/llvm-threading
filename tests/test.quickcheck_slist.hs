{-# LANGUAGE ScopedTypeVariables #-}
import Control.Monad
import Data.List
import Data.Word
import Foreign.Marshal.Alloc
import Foreign.Marshal.Array
import Foreign.Ptr
import System.IO
import Test.QuickCheck
import Test.QuickCheck.Monadic

main = do
    report "---- QUEUE SORTED LIST TESTS ----\n"
    report "Checking null cases:\n"
    res1 <- getItem nullPtr
    if res1 == nullPtr
      then report "  GetItem from null: PASSED\n"
      else report "  GetItem from null: FAILED\n"
    res2 <- getLength nullPtr
    if res2 == 0
      then report "  Length of null: PASSED\n"
      else report "  Length of null: FAILED\n"
    report "Starting QuickCheck cases.\n"
    runQC "  prop_emptyAddOneInverts: " prop_emptyAddOneInverts
    runQC "  prop_emptyAddOneLen1: " prop_emptyAddOneLen1
    runQC "  prop_lengthWorksBase: " prop_lengthWorksBase
    runQC "  prop_genericAdd1Len: " prop_genericAdd1Len
    runQC "  prop_genericRem1Len: " prop_generalRem1Len
    runQC "  prop_enqueueSorts: " prop_enqueueDequeueSorts

runQC :: Testable prop => String -> prop -> IO ()
runQC name prop = do
    report name
    quickCheckWith (stdArgs{ maxSuccess = 1000 }) prop

prop_emptyAddOneInverts :: Ptr Word8 -> Property
prop_emptyAddOneInverts ptr = monadicIO $ do
    out <- run $ do queue <- buildList []
                    addItem queue ptr
                    res <- getItem queue
                    freeList queue
                    return res
    assert (out == ptr)

prop_emptyAddOneLen1 :: Ptr Word8 -> Property
prop_emptyAddOneLen1 ptr = monadicIO $ do
    out <- run $ do queue <- buildList []
                    addItem queue ptr
                    res <- getLength queue
                    freeList queue
                    return res
    assert (out == 1)

prop_lengthWorksBase :: [Ptr Word8] -> Property
prop_lengthWorksBase ptrs = monadicIO $ do
    out <- run $ do queue <- buildList ptrs
                    res <- getLength queue
                    freeList queue
                    return res
    assert (fromIntegral out == length ptrs)

prop_genericAdd1Len :: [Ptr Word8] -> Ptr Word8 -> Property
prop_genericAdd1Len ptrs ptr = monadicIO $ do
    out <- run $ do queue <- buildList ptrs
                    startLen <- getLength queue
                    addItem queue ptr
                    endLen <- getLength queue
                    freeList queue
                    return (endLen - startLen == 1)
    assert out

prop_generalRem1Len :: [Ptr Word8] -> Property
prop_generalRem1Len ptrs = monadicIO $ do
    pre (length ptrs > 0)
    out <- run $ do queue <- buildList ptrs
                    startLen <- getLength queue
                    _ <- getItem queue
                    endLen <- getLength queue
                    freeList queue
                    return (startLen - endLen == 1)
    assert out

prop_enqueueDequeueSorts :: [Ptr Word8] -> Property
prop_enqueueDequeueSorts ptrs = monadicIO $ do
    out <- run $ do queue <- buildList ptrs
                    ls <- forM ptrs $ \ _ -> getItem queue
                    freeList queue
                    return ls
    assert (out == sortBy wordSort ptrs)
 where
  wordSort ptr1 ptr2 =
    let word1 :: Word64 = fromIntegral $ ptr1 `minusPtr` nullPtr
        word2 :: Word64 = fromIntegral $ ptr2 `minusPtr` nullPtr
    in compare word1 word2

instance Arbitrary (Ptr a) where
    arbitrary = do base <- arbitrary
                   return (nullPtr `plusPtr` base)

report :: String -> IO ()
report x = putStr x >> hFlush stdout

buildList :: [Ptr Word8] -> IO (Ptr Word8)
buildList items = do
    ptr <- newSortedList
    forM_ items $ \ item -> addItem ptr item
    return ptr

freeList :: Ptr Word8 -> IO ()
freeList q = do
    numItems <- getLength q
    if numItems == 0
        then freeList' q
        else do _ <- getItem q
                freeList q 

foreign import ccall unsafe "slist.h newSortedListLT"
  newSortedList :: IO (Ptr Word8)

foreign import ccall unsafe "slist.h addSortListItem"
  addItem :: Ptr Word8 -> Ptr Word8 -> IO ()

foreign import ccall unsafe "slist.h getSortListItem"
  getItem :: Ptr Word8 -> IO (Ptr Word8)

foreign import ccall unsafe "slist.h getSortListLength"
  getLength :: Ptr Word8 -> IO Word64

foreign import ccall unsafe "slist.h freeSortList"
  freeList' :: Ptr Word8 -> IO ()
