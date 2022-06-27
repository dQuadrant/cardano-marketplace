import qualified Test.ReferenceScriptTest as ReferenceScriptTest
import qualified Test.ReferenceDataTest as ReferenceDataTest
import qualified Test.CollateralReturnTest as CollateralReturnTest

import           Test.Tasty

main :: IO ()
main = do
    CollateralReturnTest.collateralReturnTestIO
    print "Done"
