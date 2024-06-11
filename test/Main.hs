-- import qualified Test.ReferenceScriptTest as ReferenceScriptTest
-- import qualified Test.ReferenceDataTest as ReferenceDataTest

-- import           Test.Tasty
import qualified Test.TestStorySimpleMarketV2 as StorySimpleMarketV2
import qualified Test.TestStorySimpleMarketV3 as StorySimpleMarketV3
import System.Environment (setEnv)

main :: IO ()
main = do
    setEnv "JUNIT_ENABLED" "1"
    setEnv "JUNIT_OUTPUT_DIRECTORY" "./test-reports/v2"
    setEnv "JUNIT_SUITE_NAME" "v2-marketplace-test"
    StorySimpleMarketV2.main
    setEnv "JUNIT_OUTPUT_DIRECTORY" "./test-reports/v3"
    setEnv "JUNIT_SUITE_NAME" "v3-marketplace-test"
    StorySimpleMarketV3.main
