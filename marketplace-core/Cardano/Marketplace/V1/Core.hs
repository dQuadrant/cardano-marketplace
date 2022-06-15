{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}

module Cardano.Marketplace.V1.Core where

import Cardano.Api
import Cardano.Api.Shelley (ProtocolParameters, ReferenceScript (ReferenceScriptNone), fromPlutusData, scriptDataToJsonDetailedSchema, toPlutusData)
import qualified Cardano.Api.Shelley as Shelley
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers
import Cardano.Kuber.Util
import Cardano.Ledger.Alonzo.Tx (TxBody (txfee))
import qualified Cardano.Ledger.BaseTypes as Shelley (Network (..))
import Cardano.Marketplace.Common.TextUtils
import Cardano.Marketplace.Common.TransactionUtils
import Codec.Serialise (serialise)
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.Text as Aeson
import qualified Data.Map as Map
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Lazy as TLE
import Plutus.Contracts.V2.SimpleMarketplace hiding (Withdraw)
import qualified Plutus.Contracts.V2.SimpleMarketplace as SMP
import Plutus.V1.Ledger.Api hiding (Address, TxOut, Value, getTxId)
import qualified Plutus.V1.Ledger.Api (Address)
import qualified Plutus.V1.Ledger.Api as Plutus

mint ctx signKey addrEra assetName amount = do
  let script = RequireSignature (verificationKeyHash $ getVerificationKey signKey)
      txBuilder =
        txWalletAddress addrEra
          <> txMintSimpleScript script [(assetName, amount)]
  submitTransaction ctx txBuilder signKey

sellToken :: ChainInfo v => v -> String -> Integer -> SigningKey PaymentKey -> Address ShelleyAddr -> IO ()
sellToken ctx itemStr cost sKey marketAddr = do
  let addrShelley = skeyToAddr sKey (getNetworkId ctx)
      sellerAddrInEra = getAddrEraFromSignKey ctx sKey
  item <- parseAssetNQuantity $ T.pack itemStr
  let lockedValue = valueFromList [item, (AdaAssetId, 2_000_000)]
      saleDatum = constructDatum addrShelley cost
      txOperations =
        txPayToScriptWithData (marketAddressInEra $ getNetworkId ctx) lockedValue saleDatum
          <> txWalletAddress sellerAddrInEra
  submitTransaction ctx txOperations sKey
  putStrLn "\nDatum to be used for buying :"
  putStrLn $ encodeScriptData saleDatum
  putStrLn $ "\nMarket Address : " ++ T.unpack (serialiseAddress marketAddr)

data UtxoWithData = UtxoWithData
  {
   txIn :: TxIn,
   txOut :: TxOut CtxUTxO BabbageEra,
   scriptData :: ScriptData,
   simpleSale :: SimpleSale,
   sellerAddr :: AddressInEra BabbageEra
  }

buyToken :: ChainInfo v => v -> Text -> Maybe String -> SigningKey PaymentKey -> Address ShelleyAddr -> IO ()
buyToken ctx txInText datumStrM sKey marketAddr = do
  dcInfo <- withDetails ctx
  UtxoWithData txIn txOut scriptData sSale@(SimpleSale _ priceOfAsset) sellerAddrInEra <- getUtxoWithData ctx txInText datumStrM marketAddr
  let sellerPayOperation = txPayTo sellerAddrInEra (ensureMinAda sellerAddrInEra (lovelaceToValue $ Lovelace priceOfAsset) (dciProtocolParams dcInfo))
  redeemMarketUtxo dcInfo txIn txOut sKey sellerPayOperation scriptData SMP.Buy

withdrawToken :: ChainInfo v => v -> Text -> Maybe String -> SigningKey PaymentKey -> Address ShelleyAddr -> IO ()
withdrawToken ctx txInText datumStrM sKey marketAddr = do
  dcInfo <- withDetails ctx
  UtxoWithData txIn txOut scriptData _ sellerAddrInEra <- getUtxoWithData ctx txInText datumStrM marketAddr
  let sellerSignOperation = txSignBy sellerAddrInEra
  redeemMarketUtxo dcInfo txIn txOut sKey sellerSignOperation scriptData SMP.Withdraw

getUtxoWithData :: ChainInfo v => v -> Text -> Maybe String -> Address ShelleyAddr -> IO UtxoWithData
getUtxoWithData ctx txInText datumStrM marketAddr= do 
  txIn <- parseTxIn txInText
  UTxO uMap <- queryMarketUtxos ctx marketAddr
  let txOut = unMaybe "Error couldn't find the given txin in market utxos." $ Map.lookup txIn uMap
  (scriptData, simpleSale) <- getSimpleSaleTuple datumStrM txOut
  let nwId = getNetworkId ctx
      sellerAddrInEra = plutusAddressToAddressInEra nwId (sellerAddress simpleSale)
  pure $ UtxoWithData txIn txOut scriptData simpleSale sellerAddrInEra

getSimpleSaleTuple :: Maybe String -> TxOut CtxUTxO BabbageEra -> IO (ScriptData, SimpleSale)
getSimpleSaleTuple datumStrM txOut = case datumStrM of
    Nothing -> do
      putStrLn "No datum provided. Using the one from the txout inline datum."
      let inlineDatum = findInlineDatumFromTxOut txOut
          simpleSale = unMaybe "Failed to convert datum to SimpleSale" $ Plutus.fromData $ toPlutusData inlineDatum
      pure (inlineDatum, simpleSale)
    Just datumStr -> do
      simpleSaleTuple@(scriptData, _) <- parseSimpleSale datumStr
      let datumHashMatches = matchesDatumhash (hashScriptData scriptData) txOut
      if not datumHashMatches
        then error "Error : The given txin doesn't match the datumhash of the datum."
        else pure simpleSaleTuple

redeemMarketUtxo :: DetailedChainInfo -> TxIn -> TxOut CtxUTxO BabbageEra -> SigningKey PaymentKey -> TxBuilder -> ScriptData -> SMP.MarketRedeemer -> IO ()
redeemMarketUtxo dcInfo txIn txOut sKey extraOperations scriptData redeemer = do
  let walletAddr = getAddrEraFromSignKey dcInfo sKey
      redeemUtxoOperation = txRedeemUtxo txIn txOut marketScriptToScriptInAnyLang scriptData (fromPlutusData $ toData redeemer) (Just $ ExecutionUnits 10000000 10000000000)
      txOperations =
        redeemUtxoOperation
          <> txWalletAddress walletAddr
          <> extraOperations
  submitTransaction dcInfo txOperations sKey
  putStrLn "Done"

marketScriptToScriptInAnyLang :: ScriptInAnyLang
marketScriptToScriptInAnyLang = ScriptInAnyLang (PlutusScriptLanguage PlutusScriptV2) (PlutusScript PlutusScriptV2 simpleMarketplacePlutusV2)

ensureMinAda :: AddressInEra BabbageEra -> Value -> ProtocolParameters -> Value
ensureMinAda addr value pParams =
  if diff > 0
    then value <> lovelaceToValue diff
    else value
  where
    diff = minLovelace - currentLovelace
    minLovelace = unMaybe "minLovelace calculation error" $ calculateTxoutMinLovelace (TxOut addr (TxOutValue MultiAssetInBabbageEra value) TxOutDatumNone ReferenceScriptNone) pParams
    currentLovelace = selectLovelace value

findInlineDatumFromTxOut :: TxOut CtxUTxO BabbageEra -> ScriptData
findInlineDatumFromTxOut (TxOut _ _ (TxOutDatumInline _ sd) _) = sd
findInlineDatumFromTxOut _ = error "Error : The given txin doesn't have an inline datum. Please provide a datum using --datum '<datum string>'."

matchesDatumhash :: Hash ScriptData -> TxOut ctx era -> Bool
matchesDatumhash datumHash (TxOut _ (TxOutValue _ value) (TxOutDatumHash _ hash) _) = hash == datumHash
matchesDatumhash _ _ = False
