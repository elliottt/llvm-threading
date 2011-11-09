import Control.Monad
import Data.Word
import Foreign.Marshal.Alloc
import Foreign.Marshal.Array
import Foreign.Ptr
import System.IO
import Test.QuickCheck
import Test.QuickCheck.Monadic

main = do
    report "---- QUEUE QUICKCHECK TESTS ----"
    report "Checking null cases:\n"
    res1 <- dequeue nullPtr
    if res1 == nullPtr
      then report "  Dequeue from null: PASSED\n"
      else report "  Dequeue from null: FAILED\n"
    res2 <- qLength nullPtr
    if res2 == 0
      then report "  Length of null: PASSED\n"
      else report "  Length of null: FAILED\n"
    report "Starting QuickCheck cases.\n"
    runQC "  prop_emptyAddOneInverts: " prop_emptyAddOneInverts
    runQC "  prop_emptyAddOneLen1: " prop_emptyAddOneLen1
    runQC "  prop_lengthWorksBase: " prop_lengthWorksBase
    runQC "  prop_genericAdd1Len: " prop_genericAdd1Len
    runQC "  prop_genericRem1Len: " prop_generalRem1Len
    runQC "  prop_enqueueInverts: " prop_enqueueDequeueWorks

runQC :: Testable prop => String -> prop -> IO ()
runQC name prop = do
    report name
    quickCheckWith (stdArgs{ maxSuccess = 1000 }) prop

prop_emptyAddOneInverts :: Ptr Word8 -> Property
prop_emptyAddOneInverts ptr = monadicIO $ do
    out <- run $ do queue <- buildQueue []
                    enqueue queue ptr
                    res <- dequeue queue
                    freeQueue queue
                    return res
    assert (out == ptr)

prop_emptyAddOneLen1 :: Ptr Word8 -> Property
prop_emptyAddOneLen1 ptr = monadicIO $ do
    out <- run $ do queue <- buildQueue []
                    enqueue queue ptr
                    res <- qLength queue
                    freeQueue queue
                    return res
    assert (out == 1)

prop_lengthWorksBase :: [Ptr Word8] -> Property
prop_lengthWorksBase ptrs = monadicIO $ do
    out <- run $ do queue <- buildQueue ptrs
                    res <- qLength queue
                    freeQueue queue
                    return res
    assert (fromIntegral out == length ptrs)

prop_genericAdd1Len :: [Ptr Word8] -> Ptr Word8 -> Property
prop_genericAdd1Len ptrs ptr = monadicIO $ do
    out <- run $ do queue <- buildQueue ptrs
                    startLen <- qLength queue
                    enqueue queue ptr
                    endLen <- qLength queue
                    freeQueue queue
                    return (endLen - startLen == 1)
    assert out

prop_generalRem1Len :: [Ptr Word8] -> Property
prop_generalRem1Len ptrs = monadicIO $ do
    pre (length ptrs > 0)
    out <- run $ do queue <- buildQueue ptrs
                    startLen <- qLength queue
                    _ <- dequeue queue
                    endLen <- qLength queue
                    freeQueue queue
                    return (startLen - endLen == 1)
    assert out

prop_enqueueDequeueWorks :: [Ptr Word8] -> Ptr Word8 -> Property
prop_enqueueDequeueWorks ptrs ptr = monadicIO $ do
    out <- run $ do queue <- buildQueue ptrs
                    enqueue queue ptr
                    ptr' <- dequeue queue
                    freeQueue queue
                    return ptr'
    case ptrs of
      []        -> assert (out == ptr)
      (first:_) -> assert (out == first)

instance Arbitrary (Ptr a) where
    arbitrary = do base <- arbitrary
                   return (nullPtr `plusPtr` base)

report :: String -> IO ()
report x = putStr x >> hFlush stdout

buildQueue :: [Ptr Word8] -> IO (Ptr Word8)
buildQueue items = do
    ptr <- newQueue
    forM_ items $ \ item -> enqueue ptr item
    return ptr

freeQueue :: Ptr Word8 -> IO ()
freeQueue q = do
    numItems <- qLength q
    if numItems == 0
        then freeQueue' q
        else do _ <- dequeue q
                freeQueue q 

foreign import ccall unsafe "queue.h newQueue"
  newQueue :: IO (Ptr Word8)

foreign import ccall unsafe "queue.h freeQueue"
  freeQueue' :: Ptr Word8 -> IO ()

foreign import ccall unsafe "queue.h enqueue"
  enqueue :: Ptr Word8 -> Ptr Word8 -> IO ()

foreign import ccall unsafe "queue.h dequeue"
  dequeue :: Ptr Word8 -> IO (Ptr Word8)

foreign import ccall unsafe "queue.h queueLength"
  qLength :: Ptr Word8 -> IO Word64
