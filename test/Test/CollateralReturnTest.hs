{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Test.CollateralReturnTest where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase)
import Cardano.Marketplace.Common.TransactionUtils (getSignKey, getAddrEraFromSignKey, marketAddressShelley, submitTransaction, marketAddressInEra, printUtxos)
import Cardano.Kuber.Api
import Cardano.Api
import Cardano.Kuber.Util (getDefaultConnection, queryAddressInEraUtxos, skeyToAddr, queryUtxos, sKeyToPkh, queryTxins, skeyToAddrInEra, addressInEraToAddressAny)
import Control.Exception (throwIO, throw)
import Cardano.Marketplace.V1.Core (sellToken, createReferenceScript, UtxoWithData (..), ensureMinAda, getUtxoWithData)
import Plutus.Contracts.V2.SimpleMarketplace
    ( SimpleSale(SimpleSale), simpleMarketplacePlutusV2, simpleMarketScript )
import Data.Text (Text, pack)
import qualified Plutus.Contracts.V2.SimpleMarketplace as SMP
import Cardano.Api.Shelley ( fromPlutusData, TxBody (ShelleyTxBody), PaymentCredential )
import Plutus.V2.Ledger.Api ( toData, ToData (toBuiltinData) )
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
import qualified Data.Text as T
import Plutus.Contracts.V2.AlwaysFail (alwaysFailsScript, alwaysFailPlutusScript)
import Cardano.Kuber.Data.Parsers (parseTxIn)


tests :: TestTree
tests =
  testGroup "Collateral return Test" [
      collateralReturnTest
       -- 
  ]

collateralReturnTest :: TestTree -- ^ Test collateral return functinality
collateralReturnTest = testCase "should attach a return excess amount to a return collateral output" collateralReturnTestIO

chainInfoVasilTestnet :: IO ChainConnectInfo
chainInfoVasilTestnet = do
  let network=Testnet  (NetworkMagic 9)
  conn <-getDefaultConnection  "testnet" network
  pure $ ChainConnectInfo conn

unEither :: Either FrameworkError b -> IO b
unEither (Right b) = pure b
unEither (Left err) = error $ "Error: " ++ show err

alwaysFailScriptToScriptInAnyLang :: ScriptInAnyLang
alwaysFailScriptToScriptInAnyLang = ScriptInAnyLang (PlutusScriptLanguage PlutusScriptV2) (PlutusScript PlutusScriptV2 alwaysFailsScript)

alwaysFailScriptCredential :: Cardano.Api.Shelley.PaymentCredential
alwaysFailScriptCredential = PaymentCredentialByScript alwaysFailScriptHash
  where
    alwaysFailScriptHash = hashScript alwaysFailScript'
    alwaysFailScript' = PlutusScript PlutusScriptV2 alwaysFailsScript

collateralReturnTestIO :: IO ()
collateralReturnTestIO = do
  chainInfo <- chainInfoVasilTestnet
  let networkId = getNetworkId chainInfo
  sKey <- getSignKey "pay.skey"
  let walletAddrInEra = skeyToAddrInEra sKey networkId
  lockedTxIn <- lockValueInScript chainInfo networkId sKey walletAddrInEra
  redeemTxInFromScript chainInfo sKey walletAddrInEra lockedTxIn
  -- printUtxos chainInfo walletAddrInEra
  print "Collateral Return Test Completed Successfully"

lockValueInScript chainInfo networkId sKey walletAddrInEra= do
  let lockedValue = lovelaceToValue $ Lovelace 2_000_000
      scriptAddrInEra = makeShelleyAddressInEra networkId alwaysFailScriptCredential NoStakeAddress :: AddressInEra BabbageEra
      datum = fromPlutusData $ toData $ toBuiltinData (1::Integer)
      txOperations =
        txPayToScriptWithData scriptAddrInEra lockedValue datum
          <> txWalletAddress walletAddrInEra
  tx <- submitTransaction chainInfo txOperations sKey
  let txIn = getTxIn tx 0
  putStrLn $ "\nScript Address : " ++ T.unpack (serialiseAddress scriptAddrInEra)
  waitConfirmation chainInfo (addressInEraToAddressAny scriptAddrInEra) tx "CollateralReturnTest"  "Submit tx for placing token in script address: Waiting for conformation"
  printUtxos chainInfo scriptAddrInEra
  pure txIn

orThrow x = case x of
      Right v -> pure v
      Left e -> throw e

redeemTxInFromScript :: ChainInfo v => v
  -> SigningKey PaymentKey
  -> AddressInEra BabbageEra
  -> TxIn
  -> IO ()
redeemTxInFromScript chainInfo sKey walletAddrInEra txIn= do
  utxo@(UTxO utxoMap) <- queryAddressInEraUtxos (getConnectInfo chainInfo) [walletAddrInEra] >>= unEither
  let firstTxIn = Map.keys utxoMap !! 0
  let txOperations = txRedeemTxinWithInlineDatum txIn alwaysFailScriptToScriptInAnyLang (fromPlutusData $ toData (1::Integer)) Nothing
          <> txAddTxInCollateral firstTxIn
          <> txWalletAddress walletAddrInEra
  tx <- submitTransaction chainInfo txOperations sKey
  waitConfirmation chainInfo (addressInEraToAddressAny walletAddrInEra) tx "CollateralReturnTest"  "Submit tx for placing token in script address: "
  putStrLn "Done"

  -- let addrInEra = getAddrEraFromSignKey chainInfo scriptSaverSKey
  -- utxos@(UTxO utxoMap) <- queryAddressInEraUtxos (getConnectInfo chainInfo) [addrInEra] >>= unEither
  let marketAddr = marketAddressShelley (getNetworkId chainInfo)
  -- buyTokenUsingRefScriptIO chainInfo (pack token) Nothing sKey marketAddr
  print "Done"

-- buyTokenUsingRefScriptIO :: ChainInfo v => v -> Text -> Maybe String -> SigningKey PaymentKey -> Address ShelleyAddr -> IO ()
-- buyTokenUsingRefScriptIO ctx txInText datumStrM sKey marketAddr = do
--   dcInfo <- withDetails ctx
--   UtxoWithData txIn txOut scriptData sSale@(SimpleSale _ priceOfAsset) sellerAddrInEra <- getUtxoWithData ctx txInText datumStrM marketAddr
--   let sellerPayOperation = txPayTo sellerAddrInEra (ensureMinAda sellerAddrInEra (lovelaceToValue $ Lovelace priceOfAsset) (dciProtocolParams dcInfo))
--   redeemMarketUtxoIO dcInfo txIn txOut sKey sellerPayOperation scriptData SMP.Buy

redeemMarketUtxoIO :: DetailedChainInfo -> TxIn -> TxOut CtxUTxO BabbageEra -> SigningKey PaymentKey -> TxBuilder -> ScriptData -> SMP.MarketRedeemer -> IO ()
redeemMarketUtxoIO dcInfo txIn txOut sKey extraOperations scriptData redeemer = do
  let walletAddr = getAddrEraFromSignKey dcInfo sKey
      redeemUtxoOperation = txRedeemUtxoWithInlineDatum txIn txOut alwaysFailScriptToScriptInAnyLang (fromPlutusData $ toData redeemer) Nothing
      txOperations =
        redeemUtxoOperation
          <> txWalletAddress walletAddr
          <> extraOperations
  submitTransaction dcInfo txOperations sKey
  putStrLn "Done"

getTxFee :: Tx BabbageEra  -> Integer
getTxFee tx = case getTxBody tx of
          ShelleyTxBody sbe tb scs tbsd m_ad tsv -> case txfee tb of { Coin n -> n }

waitConfirmation :: ChainInfo v =>v -> AddressAny -> Tx BabbageEra -> [Char] -> [Char] -> IO ()
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

      _waitConfirmation   =_waitForConfirmation  ( Set.singleton walletAddr)

getTxIn tx i = TxIn ( getTxId $ getTxBody  tx) (TxIx i)
