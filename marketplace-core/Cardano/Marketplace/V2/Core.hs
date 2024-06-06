{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeApplications #-}

module Cardano.Marketplace.V2.Core where

import Cardano.Api
import Cardano.Api.Shelley (ProtocolParameters, ReferenceScript (ReferenceScriptNone), fromPlutusData, scriptDataToJsonDetailedSchema, toPlutusData)
import qualified Cardano.Api.Shelley as Shelley
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers
import Cardano.Kuber.Util
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

import qualified Debug.Trace as Debug
import Data.Functor ((<&>))
import Control.Exception (throw)
import qualified Data.Set as Set
import qualified Plutus.Contracts.V2.SimpleMarketplace as Marketplace
import PlutusLedgerApi.V2 (toData, dataToBuiltinData, FromData (fromBuiltinData))


mint ::  VerificationKey PaymentKey -> AssetName -> Integer -> TxBuilder
mint vKey assetName amount = 
  let script = RequireSignature $ verificationKeyHash vKey
  in txMintSimpleScript @(SimpleScript ) script [(assetName, Quantity amount)]


createReferenceScript ::  AddressInEra ConwayEra -> TxBuilder
createReferenceScript  receiverAddr = do
    txPayToWithReferenceScript  receiverAddr mempty ( TxScriptPlutus $ toTxPlutusScript $   simpleMarketplacePlutusV2)


sellBuilder :: AddressInEra ConwayEra ->  Value -> Integer -> AddressInEra  ConwayEra  -> TxBuilder
sellBuilder contractAddr saleItem cost  sellerAddr 
  = txPayToScriptWithData contractAddr saleItem (createSaleDatum sellerAddr cost)


withdrawRedeemer = ( unsafeHashableScriptData $ fromPlutusData$ toData Marketplace.Withdraw)
buyRedeemer = ( unsafeHashableScriptData $ fromPlutusData$ toData Marketplace.Buy)


getSimpleSaleInfo ::NetworkId -> TxOut CtxUTxO ConwayEra -> Either String  (AddressInEra ConwayEra,Integer)
getSimpleSaleInfo netId tout@(TxOut addr val datum refscript) = do 
    (SimpleSale seller price) <-  case datum of 
          TxOutDatumInline  eon sd -> case fromBuiltinData $ dataToBuiltinData$  toPlutusData $ getScriptData sd of
              Nothing -> fail "Invalid datum in the Utxo to be bought"
              Just val -> pure val
          _  ->  fail "Inline datum is not present in given utxo"

    sellerAddr <- case fromPlutusAddress netId seller of
                    Just addr -> pure addr
                    Nothing -> fail "Invalid address present in datum of the Utxo to be bought"

    pure (AddressInEra (ShelleyAddressInEra ShelleyBasedEraConway) sellerAddr, price)

buyTokenBuilder' :: NetworkId -> TxIn -> TxOut CtxUTxO ConwayEra -> Either String  TxBuilder
buyTokenBuilder' netId txIn tout = do 
    (sellerAddr , price) <- getSimpleSaleInfo netId tout
    pure $ 
      txRedeemUtxo txIn tout (simpleMarketplacePlutusV2) buyRedeemer  Nothing
        <> txPayTo   (sellerAddr) (valueFromList [ (AdaAssetId, Quantity price)])

buyTokenBuilder ::  HasChainQueryAPI api => TxIn  ->  Kontract api w FrameworkError TxBuilder
buyTokenBuilder txin  = do
  netid<- kGetNetworkId
  (tin, tout) <- resolveTxIn txin
  kWrapParser $ buyTokenBuilder' netid txin tout


withdrawTokenBuilder' :: NetworkId -> TxIn -> TxOut CtxUTxO ConwayEra -> Either String  TxBuilder
withdrawTokenBuilder' netId txIn tout = do 
    (sellerAddr , price) <- getSimpleSaleInfo netId tout
    pure $ 
      txRedeemUtxo txIn tout (simpleMarketplacePlutusV2) withdrawRedeemer  Nothing
        <> txSignBy (sellerAddr)


withdrawTokenBuilder ::  HasChainQueryAPI api => TxIn  ->  Kontract api w FrameworkError TxBuilder
withdrawTokenBuilder txin = do
  netid<- kGetNetworkId
  (tin, tout) <- resolveTxIn txin
  kWrapParser $ withdrawTokenBuilder' netid txin tout


resolveTxIn:: HasChainQueryAPI api => TxIn -> Kontract api w FrameworkError (TxIn, TxOut CtxUTxO ConwayEra)
resolveTxIn txin = do 
  (UTxO uMap) :: UTxO ConwayEra <- kQueryUtxoByTxin  $ Set.singleton txin
  case Map.toList uMap  of 
    [] -> kError NodeQueryError $ "Provided Utxo not found " ++  T.unpack (renderTxIn txin )
    [(_,tout)]-> pure (txin,tout)