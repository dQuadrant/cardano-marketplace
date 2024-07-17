{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE NumericUnderscores #-}
module Main where
import Cardano.Api
import Cardano.Kuber.Api
import System.Environment (getEnv, setEnv)
import Cardano.Marketplace.Common.TransactionUtils (getSignKey, createReferenceScript, mintNativeAsset)
import Cardano.Kuber.Util (skeyToAddrInEra, utxoSum, addressInEraToAddressAny)
import Cardano.Kuber.Data.Parsers (parseAddress)
import qualified System.Environment.Blank as Blank
import qualified Data.Text as T
import qualified Data.Set as Set
import Cardano.Kuber.Console.ConsoleWritable (toConsoleText)
import Wallet (genWallet, ShelleyWallet (..))
import ParallelUtils (runOperations, runBuildAndSubmit, waitTxConfirmation, BenchRun, monitoredSubmitTx, monitoredSubmitTx', TransactionTime (ttTx))
import Cardano.Marketplace.V3.Core (simpleMarketV3Helper)
import Cardano.Marketplace.SimpleMarketplace (SimpleMarketHelper(..))
import qualified Data.ByteString.Char8 as BS8
import Control.Concurrent.Async (forConcurrently, async, Async, wait)
import System.Directory (createDirectoryIfMissing)
import System.IO
import GHC.IO.Handle
import Data.Time.Clock (getCurrentTime)
import Data.Time (formatTime, defaultTimeLocale)
import qualified Data.Aeson as A
import qualified Data.ByteString.Lazy as BSL
import GHC.IO.Handle.FD (handleToFd)
import Reporting (writeBenchmarkReport)
import Control.Exception (SomeException, catch, Exception (displayException))
import GHC.Exception (prettyCallStack)
import GHC.Stack (callStack)
import Cardano.Ledger.BaseTypes (Globals(networkId))
import Control.Concurrent (threadDelay)
import qualified Data.Text.IO as T
import GHC.Word (Word32)


main' = do
  wallets<- mapM genWallet [0.. (25*5)]
  let addrs =  map (\(ShelleyWallet pskey sskey addr)->
             addressInEraToAddressAny addr
        ) wallets
      addrSet = Set.fromList addrs
  putStrLn ("Len addrs =" ++ show (length  addrs) )
  putStrLn ("Len addrSet =" ++ show (length  addrSet) )

  mapM_  (T.putStrLn . serialiseAddress) addrs


main= do
  currentTime <- getCurrentTime
  let dateStr = formatTime defaultTimeLocale "%Y-%m-%d_%H-%M-%S" currentTime
  let reportDir = "./test-reports"


  let transactionReportJson =   reportDir <> "/" <> (dateStr ++ "-transaction-bench" ++ ".json")
  let transactionReportMd =  reportDir <>  "/" <>  dateStr ++ "-transaction-bench" ++ ".md"
  let logFileName =  dateStr ++ "-transaction-bench" ++ ".log"


  createDirectoryIfMissing True reportDir
  logFile <- openFile (reportDir ++ "/" ++ logFileName) WriteMode
  hSetBuffering stdout LineBuffering
  hSetBuffering stderr LineBuffering
  hDuplicateTo logFile stdout
  hDuplicateTo logFile stderr
  hSetBuffering logFile LineBuffering


  chainInfo <- chainInfoFromEnv
  networkId <- evaluateKontract chainInfo  kGetNetworkId >>= throwFrameworkError
  sKey <-  getEnv "SIGNKEY_FILE" >>= getSignKey
  walletAddr <- Blank.getEnv "WALLET_ADDRESS" >>= (\case
        Just addrStr -> parseAddress @ConwayEra $ T.pack addrStr
        Nothing -> pure ( skeyToAddrInEra sKey networkId)
      )


  let marketHelper = simpleMarketV3Helper
      walletBuilder =
            txWalletSignKey sKey
        <>  txWalletAddress walletAddr

      refScriptBuilder =
        createReferenceScript (simpleMarketScript marketHelper) (plutusScriptAddr  (simpleMarketScript marketHelper) networkId )
        <> walletBuilder

  result <- evaluateKontract chainInfo $ do
    walletUtxo :: UTxO ConwayEra <- kQueryUtxoByAddress $ Set.singleton (addressInEraToAddressAny walletAddr)
    liftIO $ do
      putStrLn $ "WalletAddress  : " ++ T.unpack (serialiseAddress walletAddr)
      putStrLn $ "Wallet Balance :" ++ toConsoleText "  " (utxoSum walletUtxo)


    refTx <- monitoredSubmitTx' 0 "Create Ref Script"  (pure refScriptBuilder)
    case ttTx refTx  of
      Left e -> throwError e
      Right v -> do
        let refTxId = getTxId $ getTxBody $ v
        batches <- mapM (\i ->  setupBenchBatch i simpleMarketV3Helper (TxIn refTxId (TxIx 0)) sKey walletAddr ) [0..4]
        let runBatch batch = do
              task <- kAsync batch
              liftIO $ threadDelay 15_000_000
              pure task
        taskList <- mapM runBatch batches
        resultList <- mapM kWait taskList

        let results = concat resultList
        liftIO $ do
          BSL.writeFile transactionReportJson  (A.encode results)
          writeBenchmarkReport  results transactionReportMd

  case result of
    Right _ -> pure ()
    Left e -> putStrLn $ "Bench run Kontract error : "  ++ show e


kAsync :: Exception e => Kontract a w1 FrameworkError r -> Kontract a w2 e (Async (Either FrameworkError r))
kAsync k = do
  backend <- kGetBackend
  liftIO $  async $ evaluateKontract backend k

kWait :: Exception e => Async (Either e b) -> Kontract api w e b
kWait results = do
  result <- liftIO $ wait results
  case result of
        Left e -> KError e
        Right v -> pure v



setupBenchBatch :: (HasChainQueryAPI api, HasKuberAPI api, HasSubmitApi api) => Integer -> SimpleMarketHelper -> TxIn  -> SigningKey PaymentKey ->
   AddressInEra ConwayEra -> Kontract api w FrameworkError (Kontract api w FrameworkError [Either FrameworkError BenchRun])
setupBenchBatch  _batchNo marketHelper refScriptTxin sKey walletAddress   = do
  let walletCount ::Word32 = 25
  let startIndex = fromInteger $  _batchNo *  (toInteger walletCount * 2)
  networkId <- kGetNetworkId
  backend <- kGetBackend
  buyers <- liftIO $  mapM genWallet [ startIndex .. (startIndex + walletCount -1 )]
  sellers <- liftIO $ mapM genWallet [ startIndex + walletCount ..(startIndex + walletCount * 2 -1 )]
  liftIO $ putStrLn $ show _batchNo ++" Generated wallets for batch " ++
      " buyers : " ++ show startIndex ++ "-" ++ show (startIndex + walletCount -1)
      ++ " sellers : " ++ show (startIndex + walletCount) ++ "-" ++ show (startIndex + walletCount * 2 -1)
  let
      (mintedAsset, mintBuilder) = mintNativeAsset (getVerificationKey sKey) (AssetName $ BS8.pack "TestToken") (toInteger $  length sellers)

  let fundWallet =
        createReferenceScript (simpleMarketScript marketHelper) (plutusScriptAddr  (simpleMarketScript marketHelper) networkId )
        <> foldMap
            (\w ->  txPayTo  (wAddress w)  (valueFromList [(AdaAssetId,2_000_000),(mintedAsset, 1)])
                  <> txPayTo  (wAddress w)  (valueFromList [(AdaAssetId,5_000_000)]))
            sellers
        <>foldMap
              (\w ->  txPayTo  (wAddress w)  (valueFromList [(AdaAssetId,5_000_000)])
                    <> txPayTo  (wAddress w)  (valueFromList [(AdaAssetId,5_000_000)])
          )
            buyers
        <> mintBuilder
        <> txWalletAddress walletAddress
        <> txWalletSignKey sKey
  monitoredSubmitTx'  _batchNo "Fund Wallets" (pure fundWallet)

  let
      evaluator (index, wallets) =
        evaluateKontract backend  (runOperations index  refScriptTxin marketHelper mintedAsset wallets)
      refund = foldMap (\w -> txWalletAddress (wAddress w) <> txWalletSignKey (wPaymentSkey w)) (buyers <> sellers)
                <> txChangeAddress walletAddress
  return $ do
    result <- liftIO $
      forConcurrently  ( zip [(_batchNo * toInteger  walletCount)..] $ zip  sellers buyers)  evaluator

    catchError  ( do
          monitoredSubmitTx' _batchNo "Refund Wallet" (pure refund)
          pure result
      )
      (\e -> pure result)