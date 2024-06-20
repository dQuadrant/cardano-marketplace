{-# LANGUAGE ScopedTypeVariables #-}
module Test.Reporting 
where
import Cardano.Api
import Cardano.Api.Shelley
import Data.List (nub)
import GHC.Conc (readTVar, atomically, writeTVar)
import qualified Cardano.Ledger.Shelley.Core as L
import Control.Lens ((^.))
import qualified Cardano.Ledger.Alonzo.Scripts as L
import qualified Data.Map as Map
import qualified Cardano.Api.Ledger as L
import qualified Data.ByteString as BS
import qualified Cardano.Ledger.Alonzo.TxWits as L
import Test.TestContext

collectReports:: String -> String -> TestContext a -> IO ()
collectReports testGroup  partition  context = 
  let tempReportTvar = tcTempReport  context
      reportsTvar = tcReports context
  in
    atomically $ do
      newReports <- readTVar tempReportTvar
      writeTVar tempReportTvar []
      allReports <-  readTVar reportsTvar
      writeTVar reportsTvar (allReports ++ [TestReport testGroup partition newReports])


getTxMetrics :: Tx ConwayEra -> TxMetrics
getTxMetrics tx = case tx of 
  ShelleyTx era ledgerTx -> let 
    txWitnesses = ledgerTx ^. L.witsTxL 
    -- this should be exUnits of single script involved in the transaction
    lExUnits = map snd $ map snd $  Map.toList $ L.unRedeemers $  txWitnesses ^. L.rdmrsTxWitsL
    eUnits = case lExUnits of 
          [eunit]-> let eu = L.unWrapExUnits eunit
                        (mem,cpu) =   (L.exUnitsMem' eu,L.exUnitsSteps' eu)
                    in do 
                      Just $ ExecutionUnits mem  cpu
          _       ->  Nothing 
    in TxMetrics {
          tmFee = L.unCoin $ ledgerTx ^. L.bodyTxL ^. L.feeTxBodyL 
        , tmSize = fromIntegral $  BS.length  $ serialiseToCBOR tx
        , tmSizeL =  ledgerTx ^. L.sizeTxF
        , tmExUnit = eUnits
    }


data TxMetrics = TxMetrics {
    tmFee:: Integer
  , tmSize :: Integer
  , tmSizeL :: Integer
  , tmExUnit :: Maybe ExecutionUnits
}


writeReports :: TestContext a -> FilePath -> IO ()
writeReports context filePath = do 
  reports <- atomically $ readTVar (tcReports context)
  let reportLines = renderReports reports 
  writeFile filePath (unlines reportLines)

renderReports :: [TestReport] -> [String]
renderReports testReports = 
  let
    groups = nub (map trTestGroup testReports)
    testsByGroup :: [[TestReport]] = 
                map 
                (\grpName -> filter (\testReport  -> grpName == trTestGroup testReport) testReports ) 
                groups
    in
      ["# Test Transaction Report"]
      ++
      [ "<style>"
        , "  .improved {"
        , "    background-color: #d4edda;"
        , "  }"
        , "  .declined {"
        , "    background-color: #f8d7da;"
        , "  }"
        , "</style>"
        ]
      ++
      concatMap  renderGroupedReports testsByGroup

renderGroupedReports :: [TestReport] -> [String]
renderGroupedReports testReports = 
  let 
      tags = nub (map trTag testReports)
      allTests = concat $  map trTxDetail testReports
      testNames = nub (map  tdTestName allTests )  
      filterByName tName = filter (\tDetail -> tdTestName tDetail == tName) (allTests )
      testDetailMetric  (TxDetail tName tx ) = (tName,getTxMetrics tx) 
      -- it should never be empty.
      groupName = if null testReports then "" else trTestGroup (head testReports)
  in 
      [ "\n### " ++ groupName
        ,"<table border=\"1\">"]
      <> tableHeader tags 
      <>(
          concat $ map (\testName -> 
            renderReportRow testName  (map testDetailMetric (filterByName testName))
          ) testNames )
      <>
      ["</table>"]


renderReportRow :: String -> [(String,TxMetrics)] -> [String]
renderReportRow testName results = 
  let
      -- getReport f =  map (\(_tag,metric) ->  "<td>" ++  show (f metric)  ++ "</td>") results

      getReport' ::(Integral a,Show a )=>  (b ->  a) -> Maybe a -> [(x, b)] -> [String] 
      getReport' f  _ [] = []
      getReport' f Nothing ((_tag,metric):rest) = let value = (f metric) 
                                                  in  ("<td>" ++  showNum value  ++ "</td>") : getReport' f (Just value) rest
      getReport' f (Just earlier) ((_tag,metric):rest) = let
            currentVal = f metric 
          in
          (if earlier == currentVal
            then  "<td>" ++  showNum (f metric)  ++ "</td>"
            else (
              if earlier < currentVal 
                then "<td class=\"declined\">" ++  showNum (f metric)  ++ "</td>"
                else "<td class=\"improved\">" ++  showNum (f metric)  ++ "</td>"
            )
          ) : getReport' f (Just currentVal) rest
      showNum 0 = "-"
      showNum v = show (v)
      getReport f = getReport' f Nothing results
      exUnitf f metric = case tmExUnit metric of 
          Nothing -> 0
          Just exunits ->  f exunits
      exMemf = exUnitf executionMemory 
      exCpuf =  exUnitf executionSteps

    in  [ "<tr>"
        , "  <td>" ++ testName ++ "</td>"
        ]
        ++ getReport exMemf
        ++ getReport exCpuf
        ++ getReport tmFee
        ++ getReport tmSize
        ++[
          "</tr>"
        ]


tableHeader :: [String] ->  [String]
tableHeader tagList = 
  let 
      tagLen = length tagList
      tagHtml = map (\tag -> "    <th>" ++ tag ++ "</th>") tagList
      tagHeaders = concat $ take 4 $   repeat tagHtml
    in
      [ "<thead>"
      , "  <tr>"
      , "    <th rowspan=\"" <> show tagLen <> "\">Test Name</th>"
      , "    <th colspan=\"" <> show tagLen <> "\">Ex-Units (Mem)</th>"
      , "    <th colspan=\"" <> show tagLen <> "\">Ex-Units (CPU)</th>"
      , "    <th colspan=\"" <> show tagLen <> "\">Fee</th>"
      , "    <th colspan=\"" <> show tagLen <> "\">Tx Bytes</th>"
      , "  </tr>"
      , "  <tr>"
      ]
      ++ tagHeaders
      ++ 
      [
        "  </tr>"
      , "</thead>"
      ]