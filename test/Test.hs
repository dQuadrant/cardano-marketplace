import qualified Test.ReferenceScriptTest as ReferenceScriptTest
import           Test.Tasty

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "cardano-marketplace" [
         ReferenceScriptTest.tests
    ]