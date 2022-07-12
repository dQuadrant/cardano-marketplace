import qualified Test.ReferenceScriptTest as ReferenceScriptTest
import qualified Test.ReferenceDataTest as ReferenceDataTest

import           Test.Tasty

main :: IO ()
main = do
    ReferenceDataTest.marketFlowWithInlineDatumReferenceTxinTest  
    print "Done"
