module Test.TestContext where
import Cardano.Api
import GHC.Conc (TVar)

data TestReport = TestReport {
    trTestGroup :: String 
    , trTag :: String
    , trTxDetail :: [TxDetail]
} deriving Show

data TxDetail = TxDetail {
    tdTestName :: String
  , td:: Tx ConwayEra
} deriving Show



data TestContext a= TestContext{
    tcChainInfo:: a
  , tcNetworkId :: NetworkId
  , tcSignKey :: SigningKey PaymentKey
  , tcWalletAddr :: AddressInEra ConwayEra
  , tcReports :: TVar [TestReport]
  , tcTempReport :: TVar [TxDetail]
}