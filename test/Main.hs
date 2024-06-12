-- import qualified Test.ReferenceScriptTest as ReferenceScriptTest
-- import qualified Test.ReferenceDataTest as ReferenceDataTest

-- import           Test.Tasty
import qualified Test.TestStorySimpleMarketV2 as StorySimpleMarketV2
import qualified Test.TestStorySimpleMarketV3 as StorySimpleMarketV3
import qualified Test.TestStoryConfigurableMarketV2 as StoryConfigurableMarketV2
import qualified Test.TestStoryConfigurableMarketV3 as StoryConfigurableMarketV3
import System.Environment (setEnv)

main :: IO ()
main = do
    setEnv "JUNIT_ENABLED" "1"
    setEnv "JUNIT_OUTPUT_DIRECTORY" "./test-reports/v2/simpleMarket"
    setEnv "JUNIT_SUITE_NAME" "v2-simple-marketplace-test"
    StorySimpleMarketV2.main
    setEnv "JUNIT_OUTPUT_DIRECTORY" "./test-reports/v3/simpleMarket"
    setEnv "JUNIT_SUITE_NAME" "v3-simple-marketplace-test"
    StorySimpleMarketV3.main
    setEnv "JUNIT_OUTPUT_DIRECTORY" "./test-reports/v2/configurableMarket"
    setEnv "JUNIT_SUITE_NAME" "v2-configurable-marketplace-test"
    StoryConfigurableMarketV2.main
    setEnv "JUNIT_OUTPUT_DIRECTORY" "./test-reports/v3/configurableMarket"
    setEnv "JUNIT_SUITE_NAME" "v3-configurable-marketplace-test"
    StoryConfigurableMarketV3.main
