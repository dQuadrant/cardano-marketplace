{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Test.ReferenceScriptTest where
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase)
import Cardano.Marketplace.Common.TransactionUtils (getSignKey, getAddrEraFromSignKey, marketAddressShelley, submitTransaction, marketAddressInEra)
import Cardano.Kuber.Api
import Cardano.Api
import Cardano.Kuber.Util (getDefaultConnection, queryAddressInEraUtxos, skeyToAddr, queryUtxos, sKeyToPkh, queryTxins, skeyToAddrInEra)
import Control.Exception (throwIO, throw)
import Cardano.Marketplace.V1.Core (sellToken, createReferenceScript, UtxoWithData (..), ensureMinAda, marketScriptToScriptInAnyLang, getUtxoWithData)
import Plutus.Contracts.V2.SimpleMarketplace
    ( SimpleSale(SimpleSale), simpleMarketplacePlutusV2, simpleMarketScript )
import Data.Text (Text, pack)
import qualified Plutus.Contracts.V2.SimpleMarketplace as SMP
import Cardano.Api.Shelley ( fromPlutusData, TxBody (ShelleyTxBody) )
import Plutus.V2.Ledger.Api ( toData )
import qualified Control.Concurrent as Control
import System.Environment
import qualified Data.ByteString.Char8 as BS8
import qualified Data.Set as Set
import qualified Data.Map as Map
import Data.Time.Clock
import Data.Time.Calendar
import Data.Maybe (isJust)
import Data.Time.LocalTime (utcToLocalZonedTime, getZonedTime)
import Cardano.Kuber.Console.ConsoleWritable (ConsoleWritable(toConsoleText, toConsoleTextNoPrefix))
import qualified Plutus.V1.Ledger.Address as Plutus
import qualified Plutus.V2.Ledger.Api as Plutus
import qualified Data.Aeson as Aeson
import qualified Data.Text.Encoding as T
import qualified Text.Show as T
import qualified Data.ByteString.Lazy.Char8 as BS8L
import Data.Functor ( (<&>) )
import Cardano.Api.Byron (TxBody(ByronTxBody))
import Cardano.Ledger.Babbage.Tx (txfee)
import Cardano.Ledger.Shelley.API.Types (Coin(Coin))
import Plutus.V1.Ledger.Value (tokenName)


tests :: TestTree
tests =
  testGroup "Reference Script Test" [
      attachReferenceScriptToTxOutTest
       -- 
  ]

attachReferenceScriptToTxOutTest :: TestTree -- ^ Test that we can attach a reference script to a transaction output
attachReferenceScriptToTxOutTest = testCase "should attach a reference script to a transaction output" attachReferenceScriptToTxOutTestIO


chainInfoVasilTestnet :: IO ChainConnectInfo
chainInfoVasilTestnet = do
  let network=Testnet  (NetworkMagic 9)
  conn <-getDefaultConnection  "testnet" network
  pure $ ChainConnectInfo conn

unEither :: Either FrameworkError b -> IO b
unEither (Right b) = pure b
unEither (Left err) = error $ "Error: " ++ show err


attachReferenceScriptToTxOutTestIO :: IO ()
attachReferenceScriptToTxOutTestIO = do
  chainInfo <- chainInfoVasilTestnet
  sKey <- getSignKey "pay2.skey"
  createReferenceScript chainInfo sKey


token :: String
token = "7ace8cc4f17b0e494af8f9f5a4936e55e1fbc6759b0a1ca2dee7ac08.nabin"

sellTestIO :: IO ()
sellTestIO = do
  chainInfo <- chainInfoVasilTestnet
  sKey <- getSignKey "pay2.skey"
  let cost = 2_000_000
  let marketAddr = marketAddressShelley (getNetworkId chainInfo)
  sellToken chainInfo token cost sKey marketAddr

buyTestIO :: IO ()
buyTestIO = do
  Control.threadDelay 3
  chainInfo <- chainInfoVasilTestnet
  sKey <- getSignKey "pay.skey"
  scriptSaverSKey <- getSignKey "pay2.skey"
  let addrInEra = getAddrEraFromSignKey chainInfo scriptSaverSKey
  utxos@(UTxO utxoMap) <- queryAddressInEraUtxos (getConnectInfo chainInfo) [addrInEra] >>= unEither
  let marketAddr = marketAddressShelley (getNetworkId chainInfo)
  buyTokenUsingRefScriptIO chainInfo (pack token) Nothing sKey marketAddr
  print "Done"

buyTokenUsingRefScriptIO :: ChainInfo v => v -> Text -> Maybe String -> SigningKey PaymentKey -> Address ShelleyAddr -> IO ()
buyTokenUsingRefScriptIO ctx txInText datumStrM sKey marketAddr = do
  dcInfo <- withDetails ctx
  UtxoWithData txIn txOut scriptData sSale@(SimpleSale _ priceOfAsset) sellerAddrInEra <- getUtxoWithData ctx txInText datumStrM marketAddr
  let sellerPayOperation = txPayTo sellerAddrInEra (ensureMinAda sellerAddrInEra (lovelaceToValue $ Lovelace priceOfAsset) (dciProtocolParams dcInfo))
  redeemMarketUtxoIO dcInfo txIn txOut sKey sellerPayOperation scriptData SMP.Buy

redeemMarketUtxoIO :: DetailedChainInfo -> TxIn -> TxOut CtxUTxO BabbageEra -> SigningKey PaymentKey -> TxBuilder -> ScriptData -> SMP.MarketRedeemer -> IO ()
redeemMarketUtxoIO dcInfo txIn txOut sKey extraOperations scriptData redeemer = do
  let walletAddr = getAddrEraFromSignKey dcInfo sKey
      redeemUtxoOperation = txRedeemUtxoWithInlineDatum txIn txOut marketScriptToScriptInAnyLang (fromPlutusData $ toData redeemer) Nothing
      txOperations =
        redeemUtxoOperation
          <> txWalletAddress walletAddr
          <> extraOperations
  submitTransaction dcInfo txOperations sKey
  putStrLn "Done"


marketFlowWithInlineDatumAndReferenceScriptTest :: IO ()
marketFlowWithInlineDatumAndReferenceScriptTest = do
  chainInfo <- chainInfoFromEnv >>= withDetails
  sKey <-  getEnv "SIGNKEY_FILE" >>= getSignKey
  marketFlowWithInlineDatumAndReferenceScript chainInfo sKey

marketFlowWithInlineDatumAndReferenceScriptUnconsumedTest :: IO ()
marketFlowWithInlineDatumAndReferenceScriptUnconsumedTest = do
  chainInfo <- chainInfoFromEnv >>= withDetails
  sKey <-  getEnv "SIGNKEY_FILE" >>= getSignKey
  marketFlowWithInlineDatumAndReferenceScriptUnConsumed chainInfo sKey

marketFlowWithInlineDatumAndReferenceScript ::ChainInfo ci => ci ->  SigningKey PaymentKey ->  IO ()
marketFlowWithInlineDatumAndReferenceScript chainInfo skey = do
  let mintingOp =   txMintSimpleScript mintingScript [(assetName,1 )]
                  <>  txWalletSignKey skey
  mintTx <- txBuilderToTxIO chainInfo mintingOp >>= orThrow >>= andSubmitOrThrow
  waitConfirmation chainInfo walletAddr mintTx "Mint" ( "Submit tx for minting  1  " ++ show assetId)


  let marketAddrInEra =  marketAddressInEra (getNetworkId chainInfo)
      sellOp        =  txPayToScriptWithDataAndReference
                              simpleMarketScript
                              (valueFromList [(assetId, 1), (AdaAssetId, 18_000_000)])
                              (fromPlutusData $ toData $  SimpleSale (Plutus.Address (Plutus.PubKeyCredential $ sKeyToPkh skey) Nothing ) 100_000_000)
                    <> txWalletSignKey  skey
  sellTx <- txBuilderToTxIO chainInfo sellOp >>= orThrow >>= andSubmitOrThrow
  let sellTxIn = TxIn  (getTxId $ getTxBody sellTx) (TxIx 0)
  waitConfirmation chainInfo walletAddr sellTx "Sell" ( "Submit tx for selling " ++ show assetId ++ " at at 100A ")

  [(_,txout)]<- queryTxins (getConnectInfo chainInfo) (Set.singleton  sellTxIn) >>= orThrow <&> unUTxO <&> Map.toList

  let marketAddrInEra =  marketAddressInEra (getNetworkId chainInfo)
      withdrawOp        =  txRedeemUtxoWithInlineDatumWithReferenceScript sellTxIn sellTxIn txout  (ScriptDataConstructor 1 [])  Nothing -- (Just $ ExecutionUnits 6000000000 14000000)
                    <> txSign skey
                    <> txWalletSignKey  skey
  withdrawTx <- txBuilderToTxIO chainInfo withdrawOp >>= orThrow >>= andSubmitOrThrow
  waitConfirmation chainInfo walletAddr withdrawTx "Withdraw" ( "Submit tx for withdraw " ++ show assetId)


  where
    andSubmitOrThrow tx  = submitTx (getConnectInfo chainInfo ) tx >>= orThrow >> pure tx
    orThrow x = case x of
      Right v -> pure v
      Left e -> throw e
    mintingScript  = RequireSignature ( verificationKeyHash  $ getVerificationKey skey)
    policyId =  scriptPolicyId (SimpleScript SimpleScriptV2 mintingScript)
    assetName = AssetName $ BS8.pack  "bench-token"
    assetId = AssetId policyId assetName
    walletAddr = skeyToAddr skey (getNetworkId chainInfo)

marketFlowWithInlineDatumAndReferenceScriptUnConsumed ::ChainInfo ci => ci ->  SigningKey PaymentKey ->  IO ()
marketFlowWithInlineDatumAndReferenceScriptUnConsumed chainInfo skey = do
  randomSkey <- generateSigningKey  AsPaymentKey

  let marketAddrInEra =  marketAddressInEra (getNetworkId chainInfo)
      sellOp        =  txPayToScriptWithData
                              marketAddrInEra
                              (valueFromList [(assetId, 1), (AdaAssetId, 3_000_000)])
                              (fromPlutusData $ toData $  SimpleSale (Plutus.Address (Plutus.PubKeyCredential $ sKeyToPkh skey) Nothing ) 100_000_000)
                    <> txPayToWithReference simpleMarketScript (skeyToAddrInEra randomSkey $ getNetworkId chainInfo) (valueFromList [(AdaAssetId, 18_000_000)])
                    <> txMintSimpleScript mintingScript [(assetName, 1)]
                    <> txWalletSignKey  skey
  sellTx <- txBuilderToTxIO chainInfo sellOp >>= orThrow >>= andSubmitOrThrow
  waitConfirmation chainInfo walletAddr sellTx "Sell" ( "Submit tx for placing on sale " ++ show assetId ++ " at at 100A ")

  let sellTxIn = TxIn  (getTxId $ getTxBody sellTx) (TxIx 0)
  let referenctTxin = TxIn  (getTxId $ getTxBody sellTx) (TxIx 1)

  [(_,txout)]<- queryTxins (getConnectInfo chainInfo) (Set.singleton  sellTxIn) >>= orThrow <&> unUTxO <&> Map.toList

  let   withdrawOp  =  txRedeemUtxoWithInlineDatumWithReferenceScript referenctTxin sellTxIn  txout  (ScriptDataConstructor 1 [])  Nothing -- (Just $ ExecutionUnits 6000000000 14000000)
                    <> txSign skey
                    <> txWalletSignKey  skey
  withdrawTx <- txBuilderToTxIO chainInfo withdrawOp >>= orThrow >>= andSubmitOrThrow

  waitConfirmation chainInfo walletAddr withdrawTx "Withdraw" ( "Submit tx for withdraw " ++ show assetId)


  where
    andSubmitOrThrow tx  = submitTx (getConnectInfo chainInfo ) tx >>= orThrow >> pure tx
    orThrow x = case x of
      Right v -> pure v
      Left e -> throw e
    mintingScript  = RequireSignature ( verificationKeyHash  $ getVerificationKey skey)
    policyId =  scriptPolicyId (SimpleScript SimpleScriptV2 mintingScript)
    assetName = AssetName $ BS8.pack  "bench-token"
    assetId = AssetId policyId assetName
    walletAddr = skeyToAddr skey (getNetworkId chainInfo)
    walletAddrInEra = skeyToAddrInEra skey (getNetworkId chainInfo)


getTxFee :: Tx BabbageEra  -> Integer
getTxFee tx = case getTxBody tx of
          ShelleyTxBody sbe tb scs tbsd m_ad tsv -> case txfee tb of { Coin n -> n }

waitConfirmation :: ChainInfo v =>v -> Address addr -> Tx BabbageEra -> [Char] -> [Char] -> IO ()
waitConfirmation chainInfo walletAddr tx tag message = do
  time <- getZonedTime
  putStrLn $ show time  ++  " ["++ tag ++ "\t] : " ++ "TxFee = "++show (fromIntegral  (getTxFee tx) /1e6) ++" Ada  : "++ message
  _waitConfirmation  
  time <- getZonedTime
  putStrLn $ show time  ++  " [ Confirm ] : " ++ "Tx confirmed "  ++ show xHash
  where
      xHash = getTxId $ getTxBody tx

      orThrow x = case x of
        Right v -> pure v
        Left e -> throw e
      _waitForConfirmation  addrs = do
        (UTxO utxos) <- queryUtxos  (getConnectInfo chainInfo) addrs   >>= orThrow
        if  any (\(TxIn id _) -> xHash == id) (Map.keys utxos)
          then pure()
          else  do
            Control.threadDelay 2_000_000
            _waitForConfirmation  addrs

      _waitConfirmation   =_waitForConfirmation  ( Set.singleton $ toAddressAny walletAddr)