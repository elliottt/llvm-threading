{-# LANGUAGE ScopedTypeVariables #-}
import Control.Applicative
import Control.Exception hiding (assert)
import Control.Monad
import Data.Int
import Data.List hiding (null)
import Data.Word
import Foreign.Marshal.Alloc
import Foreign.Ptr
import Foreign.Storable
import Prelude hiding (null,LT)
import System.Time hiding (toClockTime)
import Test.Framework
-- import Test.Framework.Runners.Console
import Test.Framework.Providers.HUnit
import Test.Framework.Providers.Program
import Test.Framework.Providers.QuickCheck2
import Test.HUnit hiding (assert,Test)
import Test.QuickCheck
import Test.QuickCheck.Monadic

import Debug.Trace

baseTests :: [Test]
baseTests = [
  testGroup "Data Structure Tests" [
    testGroup "Queue Tests" [
      testCase "Dequeuing from NULL is NULL" qDequeueNullGetNull
    , testCase "Queue length of NULL is 0" qLengthNullIs0
    , testProperty "Add one to empty inverts" propq_emptyAddOneInverts
    , testProperty "Add one to empty has length 1" propq_emptyAddOneLen1
    , testProperty "Length works" propq_lengthWorksBase
    , testProperty "Generic add 1 length works" propq_genericAdd1Len
    , testProperty "Generic remove 1 length works" propq_generalRem1Len
    , testProperty "Enqueue / dequeue inverts" propq_enqueueDequeueWorks
    ],
    testGroup "Sorted List Tests" [
      testCase "Dequeuing from NULL is NULL" slDequeueNullGetNull
    , testCase "Queue length of NULL is 0" slLengthNullIs0
    , testProperty "Add one to empty inverts" propsl_emptyAddOneInverts
    , testProperty "Add one to empty has length 1" propsl_emptyAddOneLen1
    , testProperty "Length works" propsl_lengthWorksBase
    , testProperty "Generic add 1 length works" propsl_genericAdd1Len
    , testProperty "Generic remove 1 length works" propsl_generalRem1Len
    , testProperty "Enqueue / dequeue inverts" propsl_enqueueDequeueSorts
    ],
    testGroup "Time Functions Tests" [
      testProperty "Add to 0 works" timeAddTo0Works
    , testProperty "StandardizeTime works" standardizeTimeWorks
    , testProperty "AddTime works" addTimeWorks
    , testProperty "DiffTime works" diffTimeWorks
    , testProperty "CompareTime works" compareTimeWorks
    , testProperty "Add builds diff 1" timeAddBuildsDiff1
    , testProperty "Add builds diff 2" timeAddBuildsDiff2
    , testProperty "Add builds diff 3" timeAddBuildsDiff3
    , testProperty "Add builds diff 4" timeAddBuildsDiff4
    ]
  ],
  testGroup "Maybe-Yield Tests" [
    buildCheckTest "test.maybeYield" maybeYieldCheck
  ],
  testGroup "Timer Tests" [
    buildCheckTest "test.timer1" timerCheck
  ]
 ]


makeTests :: IO [Test]
makeTests = do
  basicTs <- buildTestGroup "Basic System Tests" [
               buildGoldTest "test.basic1"
             , buildGoldTest "test.basic2"
             , buildGoldTest "test.basic3"
             ]
  chanTs  <- buildTestGroup "Channel Infrastructure Tests" [
               buildGoldTest "test.chan1"
             , buildGoldTest "test.chan2"
             , buildGoldTest "test.chan3"
             , buildGoldTest "test.chan4"
             ]
  joinTs  <- buildTestGroup "Thread-Join Tests" [
               buildGoldTest "test.join"
             ]
  timeTs  <- buildTestGroup "Time Subsystem Tests" [
               buildGoldTest "test.time1"
             , buildGoldTest "test.time2"
             , buildGoldTest "test.time3"
             ]
  sleepTs <- buildTestGroup "Sleep Tests" [
               buildGoldTest "test.sleep1"
             , buildGoldTest "test.sleep3"
             , buildGoldTest "test.sleep4"
             ]
  return $ baseTests++[basicTs, chanTs, joinTs, timeTs, sleepTs]

buildTestGroup :: String -> [IO Test] -> IO Test
buildTestGroup x ts = sequence ts >>= (return . testGroup x)

main :: IO ()
main = makeTests >>= defaultMain

-- --------------------------------------------------------------------------
--
-- Generic data structure functions / properties
--
-- --------------------------------------------------------------------------

class DataStructure a where
  newDataStructure   :: IO (Ptr a)
  addItem            :: Ptr a -> Ptr Word8 -> IO ()
  getItem            :: Ptr a -> IO (Ptr Word8)
  getLength          :: Ptr a -> IO Word64
  freeDataStructure' :: Ptr a -> IO ()

instance Arbitrary (Ptr a) where
    arbitrary = do base <- arbitrary
                   return (nullPtr `plusPtr` base)


dequeueNullGetNull :: DataStructure a => a -> Assertion
dequeueNullGetNull x = runt x nullPtr
 where
  runt :: DataStructure a => a -> Ptr a -> Assertion
  runt _ null = do
    res <- getItem null
    assertEqual "" res nullPtr

lengthNullIs0 :: DataStructure a => a -> Assertion
lengthNullIs0 x = runt x nullPtr
 where
  runt :: DataStructure a => a -> Ptr a -> Assertion
  runt _ null = do
    res <- getLength null
    assertEqual "" res 0

prop_emptyAddOneInverts :: DataStructure a => a -> Ptr Word8 -> Property
prop_emptyAddOneInverts x ptr = monadicIO $ do
    out <- run $ do queue <- buildDataStructure x []
                    addItem queue ptr
                    res <- getItem queue
                    freeDataStructure queue
                    return res
    assert (out == ptr)

prop_emptyAddOneLen1 :: DataStructure a => a -> Ptr Word8 -> Property
prop_emptyAddOneLen1 x ptr = monadicIO $ do
    out <- run $ do queue <- buildDataStructure x []
                    addItem queue ptr
                    res <- getLength queue
                    freeDataStructure queue
                    return res
    assert (out == 1)

prop_lengthWorksBase :: DataStructure a => a -> [Ptr Word8] -> Property
prop_lengthWorksBase x ptrs = monadicIO $ do
    out <- run $ do queue <- buildDataStructure x ptrs
                    res <- getLength queue
                    freeDataStructure queue
                    return res
    assert (fromIntegral out == length ptrs)

prop_genericAdd1Len :: DataStructure a =>
                       a -> [Ptr Word8] -> Ptr Word8 ->Property
prop_genericAdd1Len x ptrs ptr = monadicIO $ do
    out <- run $ do queue <- buildDataStructure x ptrs
                    startLen <- getLength queue
                    addItem queue ptr
                    endLen <- getLength queue
                    freeDataStructure queue
                    return (endLen - startLen == 1)
    assert out

prop_generalRem1Len :: DataStructure a =>
                       a -> [Ptr Word8] -> Property
prop_generalRem1Len x ptrs = monadicIO $ do
    pre (length ptrs > 0)
    out <- run $ do queue <- buildDataStructure x ptrs
                    startLen <- getLength queue
                    _ <- getItem queue
                    endLen <- getLength queue
                    freeDataStructure queue
                    return (startLen - endLen == 1)
    assert out

buildDataStructure :: DataStructure a => a -> [Ptr Word8] -> IO (Ptr a)
buildDataStructure _ items = do
    ptr <- newDataStructure
    forM_ items $ \ item -> addItem ptr item
    return ptr

freeDataStructure :: DataStructure a => Ptr a -> IO ()
freeDataStructure q = do
    numItems <- getLength q
    if numItems == 0
        then freeDataStructure' q
        else do _ <- getItem q
                freeDataStructure q 


-- --------------------------------------------------------------------------
--
-- Queue properties
--
-- --------------------------------------------------------------------------

qDequeueNullGetNull :: Assertion
qDequeueNullGetNull = dequeueNullGetNull Queue

qLengthNullIs0 :: Assertion
qLengthNullIs0 = lengthNullIs0 Queue

propq_emptyAddOneInverts :: Ptr Word8 -> Property
propq_emptyAddOneInverts = prop_emptyAddOneInverts Queue

propq_emptyAddOneLen1 :: Ptr Word8 -> Property
propq_emptyAddOneLen1 = prop_emptyAddOneLen1 Queue

propq_lengthWorksBase :: [Ptr Word8] -> Property
propq_lengthWorksBase = prop_lengthWorksBase Queue

propq_genericAdd1Len :: [Ptr Word8] -> Ptr Word8 -> Property
propq_genericAdd1Len = prop_genericAdd1Len Queue

propq_generalRem1Len :: [Ptr Word8] -> Property
propq_generalRem1Len = prop_generalRem1Len Queue

propq_enqueueDequeueWorks :: [Ptr Word8] -> Ptr Word8 -> Property
propq_enqueueDequeueWorks ptrs ptr = monadicIO $ do
    out <- run $ do queue <- buildDataStructure Queue ptrs
                    enqueue queue ptr
                    ptr' <- dequeue queue
                    freeDataStructure queue
                    return ptr'
    case ptrs of
      []        -> assert (out == ptr)
      (first:_) -> assert (out == first)

data Queue = Queue

instance DataStructure Queue where
  newDataStructure   = newQueue
  freeDataStructure' = freeQueue'
  addItem            = enqueue
  getItem            = dequeue
  getLength          = qLength

foreign import ccall unsafe "queue.h newQueue"
  newQueue :: IO (Ptr Queue)

foreign import ccall unsafe "queue.h freeQueue"
  freeQueue' :: Ptr Queue -> IO ()

foreign import ccall unsafe "queue.h enqueue"
  enqueue :: Ptr Queue -> Ptr Word8 -> IO ()

foreign import ccall unsafe "queue.h dequeue"
  dequeue :: Ptr Queue -> IO (Ptr Word8)

foreign import ccall unsafe "queue.h queueLength"
  qLength :: Ptr Queue -> IO Word64

-- ----------------------------------------------------------------------------
--
-- Sorted List Properties
--
-- ----------------------------------------------------------------------------

slDequeueNullGetNull :: Assertion
slDequeueNullGetNull = dequeueNullGetNull SortedList

slLengthNullIs0 :: Assertion
slLengthNullIs0 = lengthNullIs0 SortedList

propsl_emptyAddOneInverts :: Ptr Word8 -> Property
propsl_emptyAddOneInverts = prop_emptyAddOneInverts SortedList

propsl_emptyAddOneLen1 :: Ptr Word8 -> Property
propsl_emptyAddOneLen1 = prop_emptyAddOneLen1 SortedList

propsl_lengthWorksBase :: [Ptr Word8] -> Property
propsl_lengthWorksBase = prop_lengthWorksBase SortedList

propsl_genericAdd1Len :: [Ptr Word8] -> Ptr Word8 -> Property
propsl_genericAdd1Len = prop_genericAdd1Len SortedList

propsl_generalRem1Len :: [Ptr Word8] -> Property
propsl_generalRem1Len = prop_generalRem1Len SortedList

propsl_enqueueDequeueSorts :: [Ptr Word8] -> Property
propsl_enqueueDequeueSorts ptrs = monadicIO $ do
    out <- run $ do queue <- buildDataStructure SortedList ptrs
                    ls <- forM ptrs $ \ _ -> getItem queue
                    freeDataStructure queue
                    return ls
    assert (out == sortBy wordSort ptrs)
 where
  wordSort ptr1 ptr2 =
    let word1 :: Word64 = fromIntegral $ ptr1 `minusPtr` nullPtr
        word2 :: Word64 = fromIntegral $ ptr2 `minusPtr` nullPtr
    in compare word1 word2

data SortedList = SortedList

instance DataStructure SortedList where
  newDataStructure   = newSortedList
  freeDataStructure' = slFreeList'
  addItem            = slAddItem
  getItem            = slGetItem
  getLength          = slGetLength

foreign import ccall unsafe "slist.h newSortedListLT"
  newSortedList :: IO (Ptr SortedList)

foreign import ccall unsafe "slist.h addSortListItem"
  slAddItem :: Ptr SortedList -> Ptr Word8 -> IO ()

foreign import ccall unsafe "slist.h getSortListItem"
  slGetItem :: Ptr SortedList -> IO (Ptr Word8)

foreign import ccall unsafe "slist.h getSortListLength"
  slGetLength :: Ptr SortedList -> IO Word64

foreign import ccall unsafe "slist.h freeSortList"
  slFreeList' :: Ptr SortedList -> IO ()

-- ----------------------------------------------------------------------------
--
-- Time-Based Properties
--
-- ----------------------------------------------------------------------------

data LibraryTime = LT Int64 Int32
 deriving Show

instance Arbitrary LibraryTime where
    arbitrary = do secs <- arbitrary
                   nsecs <- arbitrary
                   let nsecs' = (nsecs `mod` 1000000000) * signum nsecs
                   if signum secs + fromIntegral (signum nsecs') == 0
                     then return (LT secs (negate nsecs'))
                     else return (LT secs nsecs')

instance Eq LibraryTime where
    (LT a b) == (LT c d) = (a == c) && (b == d)

instance Storable LibraryTime where
    sizeOf _          = 12
    alignment _       = 1
    peek ptr          = do secs  <- peek (castPtr ptr)
                           nsecs <- peek (castPtr (ptr `plusPtr` 8))
                           return (LT secs nsecs)
    poke ptr (LT a b) = do poke (castPtr ptr) a
                           poke (castPtr $ ptr `plusPtr` 8) b

invertTime :: LibraryTime -> LibraryTime
invertTime (LT a b) = LT (-a) (-b)

toClockTime :: LibraryTime -> ClockTime
toClockTime (LT sec nsec) = 
    case trace ("psec': " ++ show psec') () of
      () | psec' < 0 -> TOD (sec' - 1) (1000000000000 + psec')
         | otherwise -> TOD sec' psec'
 where
  sec'  = fromIntegral sec
  psec' = (fromIntegral nsec :: Integer) * 1000

fromClockTime :: ClockTime -> LibraryTime
fromClockTime (TOD sec psec) = LT sec' nsec'
 where
  sec'  = fromIntegral sec
  nsec' = fromIntegral (psec `div` 1000)

cleanLibraryTime :: LibraryTime -> LibraryTime
cleanLibraryTime = fromClockTime . toClockTime

cleanClockTime :: ClockTime -> ClockTime
cleanClockTime = toClockTime . fromClockTime

timeAddTo0Works :: LibraryTime -> Property
timeAddTo0Works time = monadicIO $ do
  res <- run $ addTime' time (LT 0 0)
  assert (res == time)

timeAddBuildsDiff1 :: LibraryTime -> LibraryTime -> Property
timeAddBuildsDiff1 time1 time2 = monadicIO $ do
  diff <- run $ do sum <- addTime' time1 time2
                   diffTime' time1 sum
  assert (diff == invertTime time2)

timeAddBuildsDiff2 :: LibraryTime -> LibraryTime -> Property
timeAddBuildsDiff2 time1 time2 = monadicIO $ do
  diff <- run $ do sum <- addTime' time1 time2
                   diffTime' time2 sum
  assert (diff == invertTime time1)

timeAddBuildsDiff3 :: LibraryTime -> LibraryTime -> Property
timeAddBuildsDiff3 time1 time2 = monadicIO $ do
  diff <- run $ do sum <- addTime' time1 time2
                   diffTime' sum time1
  assert (diff == time2)

timeAddBuildsDiff4 :: LibraryTime -> LibraryTime -> Property
timeAddBuildsDiff4 time1 time2 = monadicIO $ do
  diff <- run $ do sum <- addTime' time1 time2
                   diffTime' sum time2
  assert (diff == time1)


-- ----------------------------------

standardizeTimeWorks :: LibraryTime -> Property
standardizeTimeWorks x = monadicIO $ do
  shouldBe <- run $ standardizeTimeSpec x
  implIs   <- run $ standardizeTime x
  assert (shouldBe == implIs)

standardizeTimeSpec :: LibraryTime -> IO LibraryTime
standardizeTimeSpec x@(LT sec nsec)
  | nsec >= 1000000000      =
      standardizeTimeSpec (LT (sec + 1) (nsec - 1000000000))
  | nsec <= (-1000000000)   =
      standardizeTimeSpec (LT (sec - 1) (nsec + 1000000000))
  -- if sec is -5 and nsec is 5000, then we're really -4 and nsec (10^9 - 5000) 
  | (sec < 0) && (nsec > 0) =   
      standardizeTimeSpec (LT (sec + 1) (nsec - 1000000000))
  -- if sec is 5 and sec is -5000, then we're really 4 and nsec (10^9 - 5000)
  | (sec > 0) && (nsec < 0) =
      standardizeTimeSpec (LT (sec - 1) (1000000000 + nsec))
  | otherwise               =
      return x

standardizeTime :: LibraryTime -> IO LibraryTime
standardizeTime x =
  alloca $ \ ptr -> do
    poke ptr x
    standardTime ptr
    peek ptr

foreign import ccall unsafe "time.h standardizeTime"
  standardTime :: Ptr LibraryTime ->  IO ()

-- ----------------------------------

addTimeWorks :: LibraryTime -> LibraryTime -> Property
addTimeWorks x y = monadicIO $ do
  shouldBe <- run $ addTimeSpec x y
  implIs   <- run $ addTime' x y
  assert (shouldBe == implIs)

addTimeSpec :: LibraryTime -> LibraryTime -> IO LibraryTime
addTimeSpec x y = do
  x'@(LT xsec xnsec) <- standardizeTime x
  y'@(LT ysec ynsec) <- standardizeTime y
  let base = LT (xsec + ysec) (xnsec + ynsec)
  res <- standardizeTime base
  return res

addTime' :: LibraryTime -> LibraryTime -> IO LibraryTime
addTime' x y =
  alloca $ \ ptrx ->
    alloca $ \ ptry ->
      alloca $ \ ptrz -> do
        poke ptrx x
        poke ptry y
        _ <- addTime ptrx ptry ptrz
        peek ptrz

foreign import ccall unsafe "time.h addTime"
  addTime :: Ptr LibraryTime -> Ptr LibraryTime ->
             Ptr LibraryTime -> IO (Ptr LibraryTime)

-- ----------------------------------

diffTimeWorks :: LibraryTime -> LibraryTime -> Property
diffTimeWorks x y = monadicIO $ do
  shouldBe <- run $ diffTimeSpec x y
  implIs   <- run $ diffTime' x y
  assert (shouldBe == implIs)

diffTimeSpec :: LibraryTime -> LibraryTime -> IO LibraryTime
diffTimeSpec x y = do
  x'@(LT xsec xnsec) <- standardizeTime x
  y'@(LT ysec ynsec) <- standardizeTime y
  standardizeTime $ LT (xsec - ysec) (xnsec - ynsec)

diffTime' :: LibraryTime -> LibraryTime -> IO LibraryTime
diffTime' x y =
  alloca $ \ ptrx ->
    alloca $ \ ptry ->
      alloca $ \ ptrz -> do
        poke ptrx x
        poke ptry y
        diffTime ptrx ptry ptrz
        peek ptrz

foreign import ccall unsafe "time.h diffTime"
  diffTime :: Ptr LibraryTime -> Ptr LibraryTime ->
              Ptr LibraryTime -> IO (Ptr LibraryTime)

-- ----------------------------------

compareTimeWorks :: LibraryTime -> LibraryTime -> Property
compareTimeWorks x y = monadicIO $ do
  let shouldBe = compareTimeSpec x y
  implIs <- run $ compareTime' x y
  assert (shouldBe == implIs)

compareTimeSpec :: LibraryTime -> LibraryTime -> Int64
compareTimeSpec (LT sec1 nsec1) (LT sec2 nsec2) =
  case () of
    () | sec1  > sec2  -> 1
       | sec1  < sec2  -> -1
       | nsec1 > nsec2 -> 1
       | nsec1 < nsec2 -> -1
       | otherwise     -> 0

compareTime' :: LibraryTime -> LibraryTime -> IO Int64
compareTime' x y =
  alloca $ \ ptrx ->
    alloca $ \ ptry -> do
      poke ptrx x
      poke ptry y
      compareTime ptrx ptry

foreign import ccall unsafe "time.h compareTime"
  compareTime :: Ptr LibraryTime -> Ptr LibraryTime -> IO Int64

-- --------------------------------------------------------------------------
--
-- Test builder for simple "gold" tests; tests where the output is fixed
-- and well-known.
--
-- --------------------------------------------------------------------------

buildGoldTest :: String -> IO Test
buildGoldTest base = do
  goodOutput <- readFile inputFile
  return $ testProgramOutput base executable [] (checkEq goodOutput) Nothing
 where
  executable  = "tests/" ++ base ++ ".elf"
  inputFile   = "tests/" ++ base ++ ".gold"
  checkEq x   = Just (\ y -> x == y)

buildCheckTest :: String -> (String -> Bool) -> Test
buildCheckTest base checker =
  testProgramOutput base executable [] (Just checker) Nothing
 where executable = "./tests/" ++ base ++ ".elf"

maybeYieldCheck :: String -> Bool
maybeYieldCheck str = length groupedOutput > 10
 where
  output        = lines str
  output'       = map (take 1 . drop (length "Thread #")) output
  groupedOutput = group output'

timerCheck :: String -> Bool
timerCheck str =
  case lines str of
    []               -> False
    ("res = 0":rest) -> (length rest > 20) && all (== "TICK!") rest
    _                -> False
