{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE NoImplicitPrelude #-}


module Test.ReferenceDataTest where
import Prelude hiding(log)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase)
import Cardano.Kuber.Api
import Cardano.Api
import Cardano.Kuber.Util (getDefaultConnection, queryAddressInEraUtxos, skeyToAddr, queryUtxos, sKeyToPkh, queryTxins, toPlutusAddress, dataToScriptData, toPlutusScriptHash, skeyToAddrInEra)
import Control.Exception (throwIO, throw)
import Cardano.Marketplace.V1.Core (sellToken, createReferenceScript, UtxoWithData (..), ensureMinAda, marketScriptToScriptInAnyLang, getUtxoWithData)
import Data.Text (Text, pack)
import Cardano.Api.Shelley ( fromPlutusData, TxBody (ShelleyTxBody), fromShelleyScriptHash, toShelleyScriptHash, fromShelleyAddr )
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
import Cardano.Ledger.Shelley.API.Types (Coin(Coin), Globals (networkId))
import Plutus.Contracts.V2.MarketplaceConfig (MarketConfig(MarketConfig), marketConfigAddress, marketConfigValidator, marketConfigPlutusScript, marketConfigScript)
import Plutus.Contracts.V2.ConfigurableMarketplace (configurableMarketScript, MarketConstructor (MarketConstructor), configurableMarketValidator, configurableMarketAddress, SimpleSale (..), MarketRedeemer(..) )
import qualified Data.Text as T
import Cardano.Marketplace.Common.TransactionUtils (getSignKey)
import qualified Debug.Trace as Debug
import qualified Data.Aeson as A



marketFlowWithInlineDatumReferenceTxinTest:: IO ()
marketFlowWithInlineDatumReferenceTxinTest= do
  chainInfo <- chainInfoFromEnv  >>= withDetails
  sKey <-  getEnv "SIGNKEY_FILE" >>= getSignKey
  marketFlowWithInlineDatumReferenceTxin chainInfo sKey

marketConfigScriptCredential :: PaymentCredential
marketConfigScriptCredential = PaymentCredentialByScript $ hashScript marketConfigPlutusScript

marketFlowWithInlineDatumReferenceTxin ::DetailedChainInfo ->  SigningKey PaymentKey ->  IO ()
marketFlowWithInlineDatumReferenceTxin chainInfo skey = do
  buyerSkey <- generateSigningKey  AsPaymentKey
  artistSkey <- generateSigningKey  AsPaymentKey
  operatorSkey <- generateSigningKey AsPaymentKey

  let assetCost = 10_000_000
      marketFee = 100_000_000
      marketConfig = MarketConfig ownerAddressPlutus ownerAddressPlutus 100_000_000
      marketConstructor = MarketConstructor  ( toPlutusScriptHash $  toShelleyScriptHash  $ hashScript  marketConfigPlutusScript)
      networkId = getNetworkId chainInfo
      ownerAddressPlutus = toPlutusAddress walletAddr
      configAddress = marketConfigAddress networkId
      marketScript = configurableMarketScript marketConstructor
      marketAddrInEra =  configurableMarketAddress marketConstructor networkId
      setupBuilder =
                  -- mint token for placing on sell
                  txMintSimpleScript mintingScript [(assetName, 1)]
                  -- create reference script of configurable market contract
              <>  txPayToWithReference marketScript walletAddrInEra   (valueFromList [(AdaAssetId,30_000_000)])
                  -- create marketplace config datum
              <>  txPayToScriptWithData configAddress  (valueFromList [(AdaAssetId,5_000_000)])  (fromPlutusData $ toData marketConfig)
                  -- Send the minted token for sale.
              <>  txPayToScriptWithData
                              marketAddrInEra
                              (valueFromList [(assetId, 1), (AdaAssetId, 2_000_000)])
                              (fromPlutusData $ toData $  SimpleSale (Plutus.Address (Plutus.PubKeyCredential $ sKeyToPkh artistSkey) Nothing ) assetCost)
                  -- donate some money to buyer so that he can buy
              <>  txPayTo (skeyToAddrInEra buyerSkey networkId) (valueFromList [(AdaAssetId,Quantity $ assetCost+marketFee+2_000_000)])
                  -- provide the wallet sign key for directly signing the transaction
              <>  txWalletSignKey skey

  putStrLn $ "MarketConfigScript address : " ++  T.unpack (serialiseAddress configAddress)
  putStrLn $ "Marketplace        address : " ++  T.unpack (serialiseAddress marketAddrInEra)

  setupTx <- txBuilderToTxIO chainInfo setupBuilder >>= orThrow

  let fee=evaluateTransactionFee (dciProtocolParams chainInfo) ( getTxBody setupTx) 1 0
  andSubmitOrThrow setupTx
  waitConfirmation chainInfo walletAddr setupTx "Setup"  "Submit tx for mint, referenceData and referenceScript creation "
  let scriptReferenceTxin = getTxIn setupTx 0
  let datumRefTxin = getTxIn setupTx 1
  let onSaleTxin = getTxIn setupTx  2


  [(_,txout)]<- queryTxins (getConnectInfo chainInfo) (Set.singleton  onSaleTxin) >>= orThrow <&> unUTxO <&> Map.toList
  log "debug" $ 
              "\nBuyer Address         : " ++ T.unpack(  serialiseAddress $ skeyToAddrInEra buyerSkey networkId)
          ++  "\nArtistAddress         : " ++ T.unpack(serialiseAddress (skeyToAddrInEra artistSkey networkId))
          ++  "\nFee payment Address   : " ++ T.unpack (serialiseToBech32  walletAddr)
          ++  "\nReference Datum txin  : " ++ T.unpack ( renderTxIn datumRefTxin)
          ++  "\nReference Script txin : " ++ T.unpack (renderTxIn scriptReferenceTxin)
          ++  "\nUtxo being bought     : " ++ T.unpack (renderTxIn onSaleTxin)

  let buyOp =  txRedeemUtxoWithInlineDatumWithReferenceScript scriptReferenceTxin onSaleTxin txout  (ScriptDataConstructor 0 [])  Nothing
            <> txReferenceTxIn datumRefTxin
            <> txPayTo (skeyToAddrInEra artistSkey networkId ) (valueFromList [(AdaAssetId,Quantity assetCost)])
            <> txPayTo walletAddrInEra (valueFromList [(AdaAssetId ,Quantity marketFee )])
            <> txWalletSignKey  buyerSkey

  buyTx <- txBuilderToTxIO chainInfo buyOp >>= orThrow >>= andSubmitOrThrow 
  waitConfirmation chainInfo (skeyToAddr buyerSkey networkId ) buyTx "Buy" ( "Submit tx for buy[with reference datum] " ++ show assetId)

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

getTxIn tx i = TxIn ( getTxId $ getTxBody  tx) (TxIx i)

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

log tag message = do
  time <- getZonedTime
  putStrLn $ show time  ++  " ["++ tag ++ "\t] : " ++ message