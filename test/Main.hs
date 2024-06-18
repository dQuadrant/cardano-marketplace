-- import qualified Test.ReferenceScriptTest as ReferenceScriptTest
-- import qualified Test.ReferenceDataTest as ReferenceDataTest

-- import           Test.Tasty
import Test.TestStorySimpleMarket (makeSimpleMarketSpecs)
import Test.TestStoryConfigurableMarket  (makeConfigurableMarketSpecs)
-- import qualified Test.TestStoryConfigurableMarket as StoryConfigurableMarketV2
-- import qualified Test.TestStoryConfigurableMarketV3 as StoryConfigurableMarketV3
import System.Environment (setEnv)
import Test.Common (testContextFromEnv)
import Test.Hspec (sequential)
import Test.Hspec.JUnit (hspecJUnit)
import Test.Hspec (hspec)
import System.IO
    ( stdout, hSetBuffering, stderr, BufferMode(LineBuffering), openFile, IOMode (WriteMode) )
import Data.Time (formatTime, getCurrentTime)
import Data.Time.Format (defaultTimeLocale)
import GHC.IO.Handle (hDuplicateTo)


main :: IO ()
main = do
    currentTime <- getCurrentTime
    let dateStr = formatTime defaultTimeLocale "%Y-%m-%d_%H-%M-%S" currentTime
    let junitDir = "./test-reports"
    let junitFileName = "v2-simple-marketplace-test-" ++ dateStr ++ ".xml"
    let logFileName = "v2-simple-marketplace-test-" ++ dateStr ++ ".log"



    logFile <- openFile (junitDir ++ "/" ++ logFileName) WriteMode
    hDuplicateTo logFile stdout
    hDuplicateTo logFile stderr
    
    hSetBuffering stdout LineBuffering
    hSetBuffering stderr LineBuffering

        -- Set environment variables
    setEnv "JUNIT_ENABLED" "1"
    setEnv "JUNIT_OUTPUT_DIRECTORY" junitDir
    setEnv "JUNIT_SUITE_NAME" "Marketplace Scenario Test"


    testContext <- testContextFromEnv
    simpleMarketSpecs <-  makeSimpleMarketSpecs 1 testContext 
    configurableMarketSpecs <- makeConfigurableMarketSpecs 3 testContext

    hspecJUnit $ sequential $ do
        sequence_  simpleMarketSpecs
        sequence_ configurableMarketSpecs

    

    
    -- Redirect stdout and stderr to log file
