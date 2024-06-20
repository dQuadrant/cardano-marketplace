import Test.TestStorySimpleMarket (makeSimpleMarketSpecs)
import Test.TestStoryConfigurableMarket  (makeConfigurableMarketSpecs)
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
import System.Directory (createDirectoryIfMissing)
import Test.Reporting (writeReports)
import Control.Exception (finally)

main :: IO ()
main = do
    currentTime <- getCurrentTime
    let dateStr = formatTime defaultTimeLocale "%Y-%m-%d_%H-%M-%S" currentTime
    let reportDir = "./test-reports"
    
    let junitFileName = dateStr ++ "-marketplace-test"  ++ ".xml"
    let logFileName = dateStr ++ "-marketplace-test" ++ ".log"
    let transactionReports =  dateStr ++ "-transaction-report" ++ ".md"

    createDirectoryIfMissing True reportDir
    logFile <- openFile (reportDir ++ "/" ++ logFileName) WriteMode
    hDuplicateTo logFile stdout
    hDuplicateTo logFile stderr
    
    hSetBuffering stdout LineBuffering
    hSetBuffering stderr LineBuffering

        -- Set environment variables
    setEnv "JUNIT_ENABLED" "1"
    setEnv "JUNIT_OUTPUT_DIRECTORY" reportDir
    setEnv "JUNIT_SUITE_NAME" "Marketplace Scenario Test"


    testContext <- testContextFromEnv
    simpleMarketSpecs <-  makeSimpleMarketSpecs 1 testContext 
    configurableMarketSpecs <- makeConfigurableMarketSpecs 3 testContext

    finally (hspecJUnit $ sequential  $ do
                sequence_  simpleMarketSpecs
                sequence_ configurableMarketSpecs
            )
        (writeReports testContext  ( reportDir <> "/" <>transactionReports))
