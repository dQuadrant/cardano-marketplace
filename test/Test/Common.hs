{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}

module Test.Common where
import Cardano.Kuber.Api
import Cardano.Api
import Cardano.Api.Shelley
import qualified Cardano.Ledger.Shelley.Core as L
import Control.Lens ((^.))
import qualified Cardano.Ledger.Alonzo.TxWits as L
import qualified Cardano.Ledger.Alonzo.Scripts as L
import qualified Cardano.Api.Ledger as L
import Cardano.Marketplace.Common.TransactionUtils
import qualified Data.ByteString.Char8 as BS8
import Test.Hspec (shouldSatisfy, expectationFailure)
import qualified Data.Map as Map
import qualified Control.Concurrent as Control
import qualified Data.Set as Set
import qualified PlutusLedgerApi.V1.Scripts as P
import Cardano.Api.Ledger (hashToBytes)
import qualified PlutusTx.Builtins as BI
import Cardano.Ledger.Shelley.API (Globals(networkId))
import System.Environment (getEnv)
import qualified System.Environment.Blank as Blank
import Cardano.Kuber.Data.Parsers (parseAddress)
import qualified Data.Text as T
import Cardano.Kuber.Console.ConsoleWritable (toConsoleText)
import Cardano.Kuber.Util
import GHC.Conc
    ( writeTVar, readTVarIO, TVar, newTVarIO, readTVar )
import GHC.Conc.Sync (atomically)
import Control.Exception (throwIO)
import qualified Data.ByteString as BS
import Data.List (nub)
import Test.TestContext

testContextFromEnv :: IO (TestContext ChainConnectInfo)
testContextFromEnv = do
  chainInfo <- chainInfoFromEnv
  networkId <- evaluateKontract chainInfo  kGetNetworkId >>= throwFrameworkError
  sKey <-  getEnv "SIGNKEY_FILE" >>= getSignKey
  walletAddr <- Blank.getEnv "WALLET_ADDRESS" >>= (\case
        Just addrStr -> parseAddress $ T.pack addrStr
        Nothing -> pure ( skeyToAddrInEra sKey networkId)
      )

  walletUtxo :: UTxO ConwayEra <- evaluateKontract chainInfo (kQueryUtxoByAddress $ Set.singleton (addressInEraToAddressAny walletAddr)) >>= throwFrameworkError
  putStrLn $ "WalletAddress  : " ++ T.unpack (serialiseAddress walletAddr)
  putStrLn $ "Wallet Balance :" ++ (toConsoleText "  "  $ utxoSum walletUtxo)
  report <- newTVarIO mempty
  tempreport <- newTVarIO mempty
  tagMetrics <- newTVarIO mempty

  pure$ TestContext {
      tcChainInfo = chainInfo
    , tcNetworkId = networkId
    , tcSignKey = sKey
    , tcWalletAddr = walletAddr
    , tcReports = report
    , tcTempReport = tempreport
    , tcTagMetrics = tagMetrics
  }

readSaleAndRefScriptVar ::  (TVar (Maybe TxId),TVar (Maybe TxId)) -> IO  ( TxId,TxId)
readSaleAndRefScriptVar (a,b) = do
     a'<-readSaleTxVar' a
     b' <- readRefUtxoTxVar' b
     pure (a',b')

readSaleTxVar'  saleVar =  readTxId saleVar "Sale"
readRefUtxoTxVar'  utxoVAr =   readTxId utxoVAr "Reference Script"

readSaleTxVar v = liftIO $ readSaleTxVar' v
readRefUtxoTxVar v = liftIO $ readRefUtxoTxVar' v
readConfigTxVar  utxoVAr =  liftIO $ readTxId utxoVAr "Market Config"

readTxId :: TVar (Maybe TxId) -> String ->  IO TxId
readTxId mTvar tag= do
  val <- readTVarIO mTvar
  case val of
      Nothing ->do
        let message=tag ++ " transaction was not successful"
        expectationFailure message
        error message
      Just txId -> pure txId

runTestContext_   c tVar n k = runTestContext   c tVar n k >> return ()

runTestContext :: (HasKuberAPI a, HasSubmitApi a, HasChainQueryAPI a) =>   TestContext a -> Maybe (TVar (Maybe TxId)) ->String ->  Kontract a w FrameworkError TxBuilder -> IO TxId
runTestContext  context txVar testName kontract = do
  result<-evaluateKontract (tcChainInfo context)  $
        performTransactionAndReport
        testName
        (
            txWalletSignKey (tcSignKey context)
          <> txWalletAddress (tcWalletAddr context))
        kontract
  let setTvar v =
        case txVar of
          Nothing -> pure ()
          Just tvar -> do
              atomically $ writeTVar  tvar v
      appendTvar v a =
        atomically $ do
            val <- readTVar v
            writeTVar v (val ++ [a])
  case result of
    Left e -> do
      setTvar Nothing
      expectationFailure $ testName ++ ": Marked as Failed"
      throwIO e
    Right tx -> do
      let txId = getTxId $ getTxBody tx
      setTvar (Just txId)
      appendTvar (tcTempReport context) (TxDetail testName tx)
      pure txId


performTransactionAndReport :: (HasKuberAPI api,HasSubmitApi api,HasChainQueryAPI api) =>
  String ->
  TxBuilder ->
  Kontract api w FrameworkError TxBuilder ->
  Kontract api w FrameworkError (Tx ConwayEra)
performTransactionAndReport action wallet = performTransactionAndReport' action (pure wallet)

performTransactionAndReport' :: (HasKuberAPI api,HasSubmitApi api,HasChainQueryAPI api) =>
  String ->
  Kontract api w FrameworkError TxBuilder ->
  Kontract api w FrameworkError TxBuilder ->
  Kontract api w FrameworkError (Tx ConwayEra)
performTransactionAndReport' action walletKontract builderKontract = do
  wallet <- walletKontract
  builder <- builderKontract
  let txBuilder= builder <> wallet
  let errorHandler e= do

        liftIO $
          putStrLn   (action ++ " Tx Failed: " ++ show e  ++ "\n" ++ (BS8.unpack $ prettyPrintJSON (txBuilder)))
        KError e

  tx <- catchError  (do
      tx<- kBuildTx txBuilder
      kSubmitTx (InAnyCardanoEra ConwayEra tx)
      liftIO $ putStrLn $ "Tx Submitted :" ++  (getTxIdFromTx tx)
      pure tx
    )
    errorHandler

  let txEnvelope =  serialiseTxLedgerCddl ShelleyBasedEraConway tx
  liftIO $ do
    putStrLn $ action ++ " Tx submitted : " ++ (BS8.unpack $  prettyPrintJSON txEnvelope)
    reportExUnitsandFee tx

  waitTxConfirmation tx 180
  liftIO $ do putStrLn $ action ++ " Tx Confirmed: " ++ (show $ getTxId (getTxBody tx))
  pure (tx)

runBuildAndSubmit :: (HasKuberAPI api, HasSubmitApi api) => TxBuilder -> Kontract api w FrameworkError (Tx ConwayEra)
runBuildAndSubmit txBuilder =  do
        tx<- kBuildTx txBuilder
        kSubmitTx (InAnyCardanoEra ConwayEra tx)
        liftIO $ putStrLn $ "Tx Submitted :" ++  (getTxIdFromTx tx)
        pure tx

reportExUnitsandFee:: Tx ConwayEra -> IO ()
reportExUnitsandFee tx = case tx of
  ShelleyTx era ledgerTx -> let
    txWitnesses = ledgerTx ^. L.witsTxL
    sizeLedger = ledgerTx ^. L.sizeTxF
    sizeCapi = fromIntegral $  BS.length  $ serialiseToCBOR tx
    -- this should be exUnits of single script involved in the transaction
    exUnits = map snd $ map snd $  Map.toList $ L.unRedeemers $  txWitnesses ^. L.rdmrsTxWitsL
    txFee=L.unCoin $ ledgerTx ^. L.bodyTxL ^. L.feeTxBodyL
    in do
      (euMem,euCpu) <-case exUnits of
            [eunit]-> let eu = L.unWrapExUnits eunit
                          (mem,cpu) =   (L.exUnitsMem' eu,L.exUnitsSteps' eu)
                      in do
                        putStrLn $  "ExUnits     :  memory = " ++ show mem ++ " cpu = " ++ show cpu
                        pure (toInteger mem, toInteger cpu)
            _       -> pure  (0,0)
      putStrLn $  "Fee      :   " ++ show txFee
      if sizeLedger /= sizeCapi
        then do
          putStrLn $  "Tx Bytes (ledger):   " ++ show sizeLedger
          putStrLn $  "Tx Bytes (api)   :   " ++ show sizeCapi
        else
          putStrLn $  "Tx Bytes  :   " ++ show sizeCapi



waitTxConfirmation :: HasChainQueryAPI a => Tx ConwayEra -> Integer
      -> Kontract a w FrameworkError ()
waitTxConfirmation tx totalWaitSecs =
    let txId = getTxId$ getTxBody tx
    in waitTxId txId  totalWaitSecs
  where
    waitTxId txId remainingSecs =
      if remainingSecs < 0
        then kError TxSubmissionError $ "Transaction not confirmed after  " ++ show totalWaitSecs ++ " secs"
        else do
          (UTxO uMap):: UTxO ConwayEra <- kQueryUtxoByTxin $  Set.singleton (TxIn txId (TxIx 0))
          liftIO $ Control.threadDelay 2_000_000
          case Map.toList uMap of
            [] -> waitTxId txId (remainingSecs - 2)
            _ -> pure ()