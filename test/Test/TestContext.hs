module Test.TestContext where
import Cardano.Api
import GHC.Conc (TVar)
import Data.Map (Map)

data TagMetric = TagMetric {
  tmTestGroup :: String,
  tmTag :: String,
  tmMetricName :: String,
  tmMetric :: String 
}


data TestReport = TestReport {
    trTestGroup :: String 
    , trTag :: String
    , trTxDetail :: [TxDetail]
} deriving Show

data TxDetail = TxDetail {
    tdTestName :: String
  , td:: Tx BabbageEra
} deriving Show



data TestContext a= TestContext{
    tcChainInfo:: a
  , tcNetworkId :: NetworkId
  , tcSignKey :: SigningKey PaymentKey
  , tcWalletAddr :: AddressInEra BabbageEra
  , tcReports :: TVar [TestReport]
  , tcTempReport :: TVar [TxDetail]
  , tcTagMetrics :: TVar [TagMetric]
}