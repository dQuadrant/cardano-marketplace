{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE EmptyDataDecls #-}
{-# LANGUAGE NoImplicitPrelude  #-}
{-# LANGUAGE TemplateHaskell    #-}
{-# OPTIONS_GHC -fno-ignore-interface-pragmas #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE NumericUnderscores#-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ViewPatterns #-}
{-# OPTIONS_GHC -fplugin-opt PlutusTx.Plugin:target-version=1.1.0 #-}

module Plutus.Contracts.V3.SimpleMarketplace(
  simpleMarketplacePlutusV3,
  simpleMarketplacePlutusV3Lazy,
  MarketRedeemer(..),
  SimpleSale(..)
)
where

import GHC.Generics (Generic)
import PlutusTx.Prelude
import Prelude(Show)
import qualified Prelude
import  PlutusTx hiding( txOutDatum)
import Data.Aeson (FromJSON, ToJSON)
import qualified PlutusTx.AssocMap as AssocMap
import qualified Data.Bifunctor
import qualified Data.ByteString.Short as SBS
import qualified Data.ByteString.Lazy  as LBS
import qualified PlutusTx.Builtins.Internal as BI
import Cardano.Api.Shelley (PlutusScript (..), PlutusScriptV3)
import Codec.Serialise ( serialise )
import PlutusLedgerApi.V3
import PlutusLedgerApi.V1.Value
import PlutusLedgerApi.V3.Contexts


{-# INLINABLE allScriptInputsCount #-}
allScriptInputsCount:: TxInfo ->Integer
allScriptInputsCount txInfo =
    foldl (\c txOutTx-> c + countTxOut txOutTx) 0 (txInfoInputs  txInfo)
  where
  countTxOut (TxInInfo _ (TxOut addr _ _ _)) = case addr of { Address cre m_sc -> case cre of
                                                              PubKeyCredential pkh -> 0
                                                              ScriptCredential vh -> 1  } 

{-# INLINABLE constrArgs #-}
constrArgs :: BuiltinData -> BI.BuiltinList BuiltinData
constrArgs bd = BI.snd (BI.unsafeDataAsConstr bd)

{-# INLINABLE parseData #-}
parseData ::FromData a =>  BuiltinData -> BuiltinString -> a
parseData d s = case fromBuiltinData  d of
  Just d -> d
  _      -> traceError s

data MarketRedeemer =  Buy | Withdraw
    deriving (Generic,FromJSON,ToJSON,Show,Prelude.Eq)
PlutusTx.makeIsDataIndexed ''MarketRedeemer [('Buy, 0), ('Withdraw,1)]


data SimpleSale=SimpleSale{
    sellerAddress:: Address, -- The main seller Note that we are using address 
    priceOfAsset:: Integer  -- cost of the value in it
  } deriving(Show,Generic)

PlutusTx.makeIsDataIndexed ''SimpleSale [('SimpleSale, 0)]    

{-# INLINABLE mkMarket #-}
mkMarket ::   ScriptContext    -> Bool
mkMarket  ctx =
  case sellerPkh of 
    Nothing -> traceError "Script Address in seller"
    Just pkh -> case  action of
        Buy       -> traceIfFalse "Multiple script inputs" (allScriptInputsCount  info == 1)  && 
                     traceIfFalse "Seller not paid" (assetClassValueOf   (valuePaidTo info pkh) adaAsset >= priceOfAsset)
        Withdraw -> traceIfFalse "Seller Signature Missing" $ txSignedBy info pkh

    where
      sellerPkh= case sellerAddress of { Address cre m_sc -> case cre of
                                                           PubKeyCredential pkh -> Just pkh
                                                           ScriptCredential vh -> Nothing  }
      info  =  scriptContextTxInfo ctx
      action = case fromBuiltinData $ getRedeemer (scriptContextRedeemer ctx) of
        Nothing -> traceError "Invalid Redeemer"
        Just r -> r
      ds@SimpleSale{sellerAddress,priceOfAsset} = case (scriptContextScriptInfo ctx ) of
        SpendingScript outRef datum -> case datum of 
          Just d ->  case fromBuiltinData  (getDatum d) of
            Nothing -> traceError "Invalid datum format"
            Just v -> v
          _ -> traceError "Missing datum" 
        _ -> traceError "Script used for other than spending"
      adaAsset=AssetClass (adaSymbol,adaToken )

mkMarketLazy :: TxInfo -> SimpleSale -> MarketRedeemer -> Bool 
mkMarketLazy  info ds@SimpleSale{sellerAddress,priceOfAsset} action =
  case sellerPkh of 
    Nothing -> traceError "Script Address in seller"
    Just pkh -> case  action of
        Buy       -> traceIfFalse "Multiple script inputs" (allScriptInputsCount  info == 1)  && 
                     traceIfFalse "Seller not paid" (assetClassValueOf   (valuePaidTo info pkh) adaAsset >= priceOfAsset)
        Withdraw -> traceIfFalse "Seller Signature Missing" $ txSignedBy info pkh

    where
      sellerPkh= case sellerAddress of { Address cre m_sc -> case cre of
                                                           PubKeyCredential pkh -> Just pkh
                                                           ScriptCredential vh -> Nothing  }
      adaAsset=AssetClass (adaSymbol,adaToken )

{-# INLINABLE mkWrappedMarket #-}
mkWrappedMarket ::  BuiltinData -> BuiltinUnit
mkWrappedMarket ctx = check $ mkMarket (parseData ctx "Invalid context")

{-# INLINABLE mkWrappedMarketLazy #-}
mkWrappedMarketLazy ::  BuiltinData -> BuiltinUnit
mkWrappedMarketLazy  ctx = check $ mkMarketLazy info datum redeemer
  where 
    context = constrArgs ctx

    redeemerFollowedByScriptInfo :: BI.BuiltinList BuiltinData
    redeemerFollowedByScriptInfo = BI.tail context

    redeemerBuiltinData :: BuiltinData
    redeemerBuiltinData = BI.head redeemerFollowedByScriptInfo

    scriptInfoData :: BuiltinData
    scriptInfoData = BI.head (BI.tail redeemerFollowedByScriptInfo)

    txInfoData :: BuiltinData 
    txInfoData = BI.head context

    datumData :: BuiltinData
    datumData = BI.head (constrArgs (BI.head (BI.tail (constrArgs scriptInfoData))))

    redeemer :: MarketRedeemer
    redeemer = parseData redeemerBuiltinData "Invalid Redeemer Type"

    datum :: SimpleSale
    datum = parseData (getDatum (unsafeFromBuiltinData datumData)) "Invalid Datum Type"

    info :: TxInfo 
    info = parseData txInfoData "Invalid TxInfo Type"

simpleMarketValidator = 
            $$(PlutusTx.compile [|| mkWrappedMarket ||])

simpleMarketValidatorLazy = 
            $$(PlutusTx.compile [|| mkWrappedMarketLazy ||])

simpleMarketplacePlutusV3 ::  PlutusScript PlutusScriptV3
simpleMarketplacePlutusV3  = PlutusScriptSerialised $ serialiseCompiledCode simpleMarketValidator

simpleMarketplacePlutusV3Lazy ::  PlutusScript PlutusScriptV3
simpleMarketplacePlutusV3Lazy  = PlutusScriptSerialised $ serialiseCompiledCode simpleMarketValidatorLazy