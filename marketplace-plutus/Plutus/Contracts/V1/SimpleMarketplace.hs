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
{-# OPTIONS_GHC -fplugin-opt PlutusTx.Plugin:target-version=1.0.0 #-}

module Plutus.Contracts.V1.SimpleMarketplace(
  simpleMarketplacePlutusV1,
  simpleMarketplacePlutusV1SuperLazy,
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
import Cardano.Api.Shelley (PlutusScript (..), PlutusScriptV1)
import Codec.Serialise ( serialise )
import PlutusLedgerApi.V1
import PlutusLedgerApi.V1.Value
import PlutusLedgerApi.V1.Contexts


{-# INLINABLE allScriptInputsCount #-}
allScriptInputsCount:: [TxInInfo] ->Integer
allScriptInputsCount inputs=
    foldl (\c txOutTx-> c + countTxOut txOutTx) 0 inputs
  where
  countTxOut input = case txInInfoResolved input of 
    (TxOut addr _ _ ) -> case addr of 
      { Address cre m_sc -> case cre of
          PubKeyCredential pkh -> 0
          ScriptCredential vh -> 1  
      } 

{-# INLINABLE parseData #-}
parseData ::FromData a =>  BuiltinData -> BuiltinString -> a
parseData d s = case fromBuiltinData  d of
  Just d -> d
  _      -> traceError s

{-# INLINABLE constrArgs #-}
constrArgs :: BuiltinData -> BI.BuiltinList BuiltinData
constrArgs bd = BI.snd (BI.unsafeDataAsConstr bd)

data MarketRedeemer =  Buy | Withdraw
    deriving (Generic,FromJSON,ToJSON,Show,Prelude.Eq)
PlutusTx.makeIsDataIndexed ''MarketRedeemer [('Buy, 0), ('Withdraw,1)]


data SimpleSale=SimpleSale{
    sellerAddress:: Address, -- The main seller Note that we are using address 
    priceOfAsset:: Integer  -- cost of the value in it
  } deriving(Show,Generic)

PlutusTx.makeIsDataIndexed ''SimpleSale [('SimpleSale, 0)]    

{-# INLINABLE mkMarket #-}
mkMarket ::  SimpleSale   -> MarketRedeemer -> ScriptContext    -> Bool
mkMarket  ds@SimpleSale{sellerAddress,priceOfAsset}  action ctx =
  case sellerPkh of 
    Nothing -> traceError "Script Address in seller"
    Just pkh -> case  action of
        Buy       -> traceIfFalse "Multiple script inputs" (allScriptInputsCount  (txInfoInputs info) == 1)  && 
                     traceIfFalse "Seller not paid" (assetClassValueOf   (valuePaidTo info pkh) adaAsset >= priceOfAsset)
        Withdraw -> traceIfFalse "Seller Signature Missing" $ txSignedBy info pkh

    where
      sellerPkh= case sellerAddress of { Address cre m_sc -> case cre of
                                                           PubKeyCredential pkh -> Just pkh
                                                           ScriptCredential vh -> Nothing  }
      info  =  scriptContextTxInfo ctx
      adaAsset=AssetClass (adaSymbol,adaToken )

{-# INLINABLE mkMarketSuperLazy #-}
mkMarketSuperLazy :: SimpleSale -> MarketRedeemer -> [TxInInfo] -> [TxOut] -> [PubKeyHash] -> Bool
mkMarketSuperLazy ds@SimpleSale{sellerAddress,priceOfAsset} action allInputs allOutputs signatures = 
  case sellerPkh of 
    Nothing -> traceError "Script Address in seller"
    Just pkh -> case  action of
        Buy       -> traceIfFalse "Multiple script inputs" (allScriptInputsCount allInputs == 1)  && 
                     traceIfFalse "Seller not paid" (assetClassValueOf  (valuePaidTo' pkh) adaAsset >= priceOfAsset)
        Withdraw -> traceIfFalse "Seller Signature Missing" $ pkh `elem` signatures

    where
      sellerPkh= case sellerAddress of { Address cre m_sc -> case cre of
                                                           PubKeyCredential pkh -> Just pkh
                                                           ScriptCredential vh -> Nothing  }
      adaAsset=AssetClass (adaSymbol,adaToken )

      valuePaidTo' pkh' = foldMap(\(TxOut _ val _ ) -> val ) filteredOutputs
        where
          filteredOutputs = mapMaybe (\x -> case x of 
            (TxOut addr _ _) -> case addr of 
              { Address cre m_sc -> case cre of
                PubKeyCredential pkh -> if pkh == pkh' then Just x else Nothing
                ScriptCredential vh -> Nothing }) allOutputs
   

{-# INLINABLE mkWrappedMarket #-}
mkWrappedMarket ::  BuiltinData -> BuiltinData -> BuiltinData -> BuiltinUnit
mkWrappedMarket  d r c = check $ mkMarket (parseData d "Invalid data") (parseData r "Invalid redeemer") (parseData c "Invalid context")

{-# INLINABLE mkWrappedMarketSuperLazy #-}
mkWrappedMarketSuperLazy ::  BuiltinData -> BuiltinData -> BuiltinData -> BuiltinUnit
mkWrappedMarketSuperLazy  d r c = 
  check $ mkMarketSuperLazy 
  (parseData d "Invalid data") 
  (parseData r "Invalid redeemer") 
  inputs 
  outputs 
  signatures
  where 
    context = constrArgs c

    txInfoData :: BuiltinData 
    txInfoData = BI.head context

    lazyTxInfo :: BI.BuiltinList BuiltinData
    lazyTxInfo = constrArgs txInfoData 

    inputs :: [TxInInfo]
    inputs = parseData (BI.head lazyTxInfo) "txInfoInputs: Invalid [TxInInfo] type"

    outputs :: [TxOut] 
    outputs = parseData (BI.head (BI.tail lazyTxInfo)) "txInfoOutputs: Invalid [TxOut] type"

    signatures :: [PubKeyHash]
    signatures = parseData 
      (BI.head $ BI.tail $ BI.tail $ BI.tail $ BI.tail $ BI.tail $ BI.tail $ BI.tail lazyTxInfo) 
      "txInfoSignatories: Invalid [PubKeyHash] type"

simpleMarketValidator = 
            $$(PlutusTx.compile [|| mkWrappedMarket ||])

simpleMarketValidatorSuperLazy = 
            $$(PlutusTx.compile [|| mkWrappedMarketSuperLazy ||])

simpleMarketplacePlutusV1 ::  PlutusScript PlutusScriptV1
simpleMarketplacePlutusV1  = PlutusScriptSerialised $ serialiseCompiledCode  simpleMarketValidator

simpleMarketplacePlutusV1SuperLazy ::  PlutusScript PlutusScriptV1
simpleMarketplacePlutusV1SuperLazy  = PlutusScriptSerialised $ serialiseCompiledCode  simpleMarketValidatorSuperLazy