-- import qualified Test.ReferenceScriptTest as ReferenceScriptTest
-- import qualified Test.ReferenceDataTest as ReferenceDataTest

-- import           Test.Tasty
import qualified Test.TestStorySimpleMarket as StorySimpleMarket
import System.Environment (setEnv)

main :: IO ()
main = do
    setEnv "JUNIT_ENABLED" "1"
    setEnv "JUNIT_OUTPUT_DIRECTORY" "./test-reports"
    setEnv "JUNIT_SUITE_NAME" "marketplace-test"
    StorySimpleMarket.main
