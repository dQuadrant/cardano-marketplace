import qualified Test.ReferenceScriptTest as ReferenceScriptTest
import           Test.Tasty

main :: IO ()
main = do
    ReferenceScriptTest.marketFlowWithInlineDatumAndReferenceScriptTest
    print "Done"
