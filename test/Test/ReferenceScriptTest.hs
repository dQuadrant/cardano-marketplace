{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Test.ReferenceScriptTest where
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase)
import Cardano.Marketplace.Common.TransactionUtils (getSignKey, getAddrEraFromSignKey, marketAddressShelley, submitTransaction)
import Cardano.Kuber.Api
import Cardano.Api
import Cardano.Kuber.Util (getDefaultConnection, queryAddressInEraUtxos)
import Control.Exception (throwIO)
import Cardano.Marketplace.V1.Core (sellToken, createReferenceScript, UtxoWithData (..), ensureMinAda, marketScriptToScriptInAnyLang, getUtxoWithData)
import Plutus.Contracts.V2.SimpleMarketplace
    ( SimpleSale(SimpleSale) )
import Data.Text (Text, pack)
import qualified Plutus.Contracts.V2.SimpleMarketplace as SMP
import Cardano.Api.Shelley ( fromPlutusData )
import Plutus.V2.Ledger.Api ( toData )


tests :: TestTree
tests =
  testGroup "Reference Script Test" [
      attachReferenceScriptToTxOutTest
  ]

chainInfoVasilTestnet :: IO ChainConnectInfo
chainInfoVasilTestnet = do
  let network=Testnet  (NetworkMagic 9)
  conn <-getDefaultConnection  "testnet" network
  pure $ ChainConnectInfo conn

unEither :: Either FrameworkError b -> IO b
unEither (Right b) = pure b
unEither (Left err) = error $ "Error: " ++ show err

attachReferenceScriptToTxOutTest :: TestTree -- ^ Test that we can attach a reference script to a transaction output
attachReferenceScriptToTxOutTest = testCase "should attach a reference script to a transaction output" attachReferenceScriptToTxOutTestIO

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
