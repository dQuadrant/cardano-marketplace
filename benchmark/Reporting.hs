{-# LANGUAGE ScopedTypeVariables #-}

module Reporting where

import Data.Time.Clock (UTCTime, diffUTCTime, NominalDiffTime)
import Data.List (nub)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Numeric (showFFloat)
import qualified Data.ByteString as BS
import Statistics.Sample (mean, stdDev)
import qualified Data.Vector as V
import Cardano.Api
import ParallelUtils
import Cardano.Api.Shelley (Tx(ShelleyTx))
import qualified Cardano.Ledger.Core as L
import Control.Lens ( (^.) )
import qualified Cardano.Ledger.Plutus as L
import qualified Data.Map as Map
import qualified Cardano.Ledger.Coin as L
import qualified Cardano.Ledger.Alonzo.TxWits as L
import qualified Data.Text as T
import Cardano.Kuber.Api (FrameworkError)
import Data.Either (isRight, rights)

-- Existing functions

writeBenchmarkReport :: [Either FrameworkError BenchRun] -> FilePath -> IO ()
writeBenchmarkReport benchRuns filePath = do
    let reportLines = renderBenchmarkReports benchRuns
    writeFile filePath (unlines $  reportLines ++ renderDetailedBenchmarkReports (rights benchRuns))

renderBenchmarkReports :: [Either FrameworkError BenchRun] -> [String]
renderBenchmarkReports benchRuns =
    let
        successfulRuns = rights  benchRuns
        testNames = nub . concatMap (map ttTxName . brTimings) $ successfulRuns
        (averages, stdDevs) = calculateStats successfulRuns testNames
    in
        ["# Benchmark Report"]
        ++
        [ "<style>"
        , "  .highlight {"
        , "    background-color: #f8d7da;"
        , "  }"
        , "</style>"
        ]
        ++ ["### Transaction times\n"]
        ++ renderStats averages stdDevs testNames
        ++ ["\n### Time Details\n"]
        ++ ["<table border=\"1\">"]
        ++ tableHeaderBenchmark testNames
        ++ concatMap (renderReportRowBenchmark testNames averages) benchRuns
        ++ ["</table>"]

calculateStats :: [BenchRun] -> [String] -> ([(String, Double)], [(String, Double)])
calculateStats benchRuns testNames =
    let
        allTimings = concatMap brTimings benchRuns
        
        timingByName name = (filter ((== name) . ttTxName) allTimings)
        
        timingsMap = map (\name -> (name, V.fromList $ map (realToFrac . diffUTCTime' ) $ timingByName name)) testNames
        means = map (\(name, vec) -> (name, mean vec)) timingsMap
        stdDevs = map (\(name, vec) -> (name, stdDev vec)) timingsMap
    in
        (means, stdDevs)
  where
    diffUTCTime' tt = diffUTCTime (ttEndTime tt) (ttStartTime tt)
    getTime :: String -> [TransactionTime] -> TransactionTime
    getTime name tts = head $ filter ((== name) . ttTxName) tts

renderStats :: [(String, Double)] -> [(String, Double)] -> [String] -> [String]
renderStats averages stdDevs testNames =
    let
        theader = ["<tr><th> </th>"]
                ++  (map (\name -> "<th>" ++ name ++ "</th>")   testNames)
                ++ ["</tr>"]
        avgHeader = "<tr><th>Average</th>" ++ concatMap (renderStat averages) testNames ++ "</tr>"
        stdDevHeader = "<tr><th>Std Deviation</th>" ++ concatMap (renderStat stdDevs) testNames ++ "</tr>"
    in
        ["<table border=\"1\">"] ++ theader ++ [ avgHeader, stdDevHeader, "</table>"]

renderStat :: [(String, Double)] -> String -> String
renderStat stats name =
    case lookup name stats of
        Just value -> "<td>" ++ showFFloat (Just 3) value "" ++ "</td>"
        Nothing -> "<td>-</td>"

renderReportRowBenchmark :: [String] -> [(String, Double)] -> Either FrameworkError BenchRun -> [String]
renderReportRowBenchmark testNames averages benchRun =
    let
        formatDuration :: NominalDiffTime -> String
        formatDuration duration = showFFloat (Just 3) (realToFrac duration :: Double) ""
        getReport tMap testName = case lookup testName tMap of
            Just duration -> let
                avg = lookup testName averages
                classAttr = case avg of
                    Just a -> if realToFrac duration > a then " class=\"highlight\"" else ""
                    Nothing -> ""
                in "<td" ++ classAttr ++ ">" ++ formatDuration duration ++ "</td>"
            Nothing -> "<td>-</td>"
    in
        ["<tr>"]++
        (case benchRun of 
            Left error -> [
                 "<td colspan=" ++ (show $ length testNames + 1) ++ ">" ++ show error ++ "</td>"
                ]
            Right successRun ->
              let  timingsMap = map (\tt -> (ttTxName tt, diffUTCTime (ttEndTime tt) (ttStartTime tt))) (brTimings successRun)
                in
                ("<td>" ++ show (brId successRun) ++ "</td>")
                
                    : map (getReport timingsMap) testNames)
        ++ ["</tr>"]

tableHeaderBenchmark :: [String] -> [String]
tableHeaderBenchmark testNames =
    let
        headers = concatMap (\name -> ["<th>" ++ name ++ "</th>"]) testNames
    in
        [ "<thead>"
        , "<tr>"
        , "<th>Run ID</th>"
        ]
        ++ headers
        ++ ["</tr>"
        , "</thead>"]

-- New function to write a detailed report

writeDetailedBenchmarkReport :: [BenchRun] -> FilePath -> IO ()
writeDetailedBenchmarkReport benchRuns filePath = do
    let reportLines = renderDetailedBenchmarkReports benchRuns
    writeFile filePath (unlines reportLines)

renderDetailedBenchmarkReports :: [BenchRun] -> [String]
renderDetailedBenchmarkReports benchRuns =
    let
        allTransactions = concatMap (\(a,b) -> map (\t -> (a,t)) $ brTimings b) (zip [0..] benchRuns)
    in
        ["\n## Transaction Details\n"]
        ++
        [ "<style>"
        , "  .highlight {"
        , "    background-color: #f8d7da;"
        , "  }"
        , "</style>"
        ]
        ++ ["<table border=\"1\">"]
        ++ detailedTableHeader
        ++ concatMap renderDetailedReportRow (allTransactions)
        ++ ["</table>"]

detailedTableHeader :: [String]
detailedTableHeader =
    [ "<thead>"
    , "<tr>"
    , "<th rowspan=2 >Run ID</th>"
    , "<th rowspan=2>Tx Name</th>"
    , "<th rowspan=2>Tx Hash</th>"
    , "<th rowspan=2>Fee</th>"
    , "<th colspan=2>Execution Units</th>"
    , "</tr>"
    , "<tr>"
    , "<th> Mem </th>"
    , "<th> Cpu </th>"
    , "</tr>"
    , "</thead>"
    ]

renderDetailedReportRow :: (Integer,TransactionTime) -> [String]
renderDetailedReportRow (index,txTime) =
    let
        tx = ttTx txTime
        metrics = getTxMetrics$  ttTx txTime
        fee = show $  txTime
        (mem, steps) = case tmExUnit metrics of
            Just (ExecutionUnits cpu mem) -> (show $ cpu, show $ mem)
            Nothing -> ("-", "-")
    in
        [ "<tr>"
        , "<td>" ++ show (index) ++ "</td>"
        , "<td>" ++ ttTxName txTime ++ "</td>"
        , "<td>" ++ T.unpack  (serialiseToRawBytesHexText  (getTxId (getTxBody tx))) ++ "</td>"
        , "<td>" ++ show (tmFee metrics) ++ "</td>"
        , "<td>" ++ mem ++ "</td>"
        , "<td>" ++ steps ++ "</td>"
        , "</tr>"
        ]


getTxMetrics :: Tx ConwayEra -> TxMetrics
getTxMetrics tx = case tx of 
  ShelleyTx era ledgerTx -> let 
    txWitnesses = ledgerTx ^. L.witsTxL
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
