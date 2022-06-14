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
import qualified Cardano.Api.Shelley as Shelley
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers
import Cardano.Kuber.Util
import Cardano.Ledger.Alonzo.Tx (TxBody (txfee))
import qualified Cardano.Ledger.BaseTypes as Shelley (Network (..))
import Cardano.Marketplace.Common.TextUtils
import Cardano.Marketplace.Common.TransactionUtils
import Codec.Serialise (serialise)
import qualified Plutus.Contracts.V2.SimpleMarketplace as SMP
import qualified Data.Map as Map
import Plutus.Contracts.V2.SimpleMarketplace hiding ( Withdraw)
import qualified Data.Aeson as Aeson
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Aeson.Text as Aeson
import Plutus.V1.Ledger.Api hiding( Address,TxOut,Value,getTxId)
import qualified Plutus.V1.Ledger.Api (Address)
import Cardano.Api.Shelley (ProtocolParameters, scriptDataToJsonDetailedSchema, fromPlutusData, ReferenceScript (ReferenceScriptNone))
import qualified Data.Text.Lazy as TLE

mint ctx signKey addrEra  assetName amount = do
  let script = RequireSignature (verificationKeyHash  $ getVerificationKey  signKey)
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
  putStrLn (TLE.unpack $ Aeson.encodeToLazyText $ scriptDataToJsonDetailedSchema saleDatum)
  putStrLn $ "\nMarket Address : " ++ T.unpack (serialiseAddress marketAddr)

buyToken :: ChainInfo v => v -> Text -> Maybe String -> SigningKey PaymentKey -> Address ShelleyAddr -> IO ()
buyToken ctx txInText datumStrM sKey marketAddr = do
  dcInfo <- withDetails ctx
  txIn <- parseTxIn txInText
  UTxO uMap <- queryMarketUtxos ctx marketAddr
  let txOut = unMaybe "Error couldn't find the given txin in market utxos." $ Map.lookup txIn uMap

  (scriptData,simpleSale@SimpleSale {sellerAddress, priceOfAsset}) <- case datumStrM of
    Nothing -> do
      putStrLn "No datum provided. Using the one from the txout inline datum."
      let datum = f
      print "ok"

    Just datumStr -> do
      simpleSaleTuple <- parseSimpleSale datumStr
      let datumHashMatches = matchesDatumhash (hashScriptData scriptData) txOut
      if not datumHashMatches
        then error "Error : The given txin doesn't match the datumhash of the datum."
        else return simpleSaleTuple
  
  let nwId = getNetworkId ctx
      buyerAddr = getAddrEraFromSignKey ctx sKey
      sellerAddrInEra = plutusAddressToAddressInEra nwId sellerAddress
      sellerPayOperation = txPayTo sellerAddrInEra (ensureMinAda sellerAddrInEra (lovelaceToValue $ Lovelace priceOfAsset) (dciProtocolParams dcInfo))
      redeemUtxoOperation = txRedeemUtxo txIn txOut marketScriptToScriptInAnyLang scriptData (fromPlutusData $ toData SMP.Buy)
      txOperations =
        sellerPayOperation
          <> redeemUtxoOperation
          <> txWalletAddress buyerAddr
  submitTransaction dcInfo txOperations sKey
  putStrLn "Done"
  where

    findDatumFromTxOut :: TxOut CtxUTxO BabbageEra-> Maybe (ScriptData, SimpleSale)
    findDatumFromTxOut (TxOut _ _ (TxOutDatumInline _ sd) _ ) = Just sd
    findDatumFromTxOut _ = Nothing

    matchesDatumhash datumHash (TxOut _ (TxOutValue _ value) (TxOutDatumHash _ hash) _) = hash == datumHash
    matchesDatumhash _ _ = False

    marketScriptToScriptInAnyLang = ScriptInAnyLang (PlutusScriptLanguage PlutusScriptV1) (PlutusScript PlutusScriptV1 simpleMarketplacePlutus)

    ensureMinAda :: AddressInEra BabbageEra -> Value -> ProtocolParameters -> Value
    ensureMinAda addr value pParams =
      if diff > 0
        then value <> lovelaceToValue diff
        else value
      where
        diff = minLovelace - currentLovelace
        minLovelace =unMaybe "minLovelace calculation error" $  calculateTxoutMinLovelace (TxOut addr (TxOutValue MultiAssetInBabbageEra  value ) TxOutDatumNone ReferenceScriptNone)  pParams
        currentLovelace = selectLovelace value

withdrawToken :: ChainInfo v => v -> Text -> Maybe String -> SigningKey PaymentKey -> Address ShelleyAddr -> IO ()
withdrawToken ctx txInText datumStrM sKey marketAddr = do
  dcInfo <- withDetails ctx
  (scriptData, simpleSale@SimpleSale {sellerAddress, priceOfAsset}) <- parseSimpleSale datumStr
  txIn <- parseTxIn txInText
  UTxO uMap <- queryMarketUtxos ctx marketAddr
  let txOut = unMaybe "Error couldn't find the given txin in market utxos." $ Map.lookup txIn uMap
  if not $ matchesDatumhash (hashScriptData scriptData) txOut
    then error "Error : The given txin doesn't match the datumhash of the datum."
    else do
      let nwId = getNetworkId ctx
          buyerAddr = getAddrEraFromSignKey ctx sKey
          sellerAddrInEra = plutusAddressToAddressInEra nwId sellerAddress
          redeemUtxoOperation = txRedeemUtxo txIn txOut marketScriptToScriptInAnyLang scriptData (fromPlutusData $ toData SMP.Withdraw)
          txOperations =
            redeemUtxoOperation
              <> txWalletAddress buyerAddr
              <> txSignBy sellerAddrInEra
      submitTransaction dcInfo txOperations sKey
      putStrLn "Done"
  where
    matchesDatumhash datumHash (TxOut _ (TxOutValue _ value) (TxOutDatumHash _ hash) _) = hash == datumHash
    matchesDatumhash _ _ = False

    marketScriptToScriptInAnyLang = ScriptInAnyLang (PlutusScriptLanguage PlutusScriptV1) (PlutusScript PlutusScriptV1 simpleMarketplacePlutus)
