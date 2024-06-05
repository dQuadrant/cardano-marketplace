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
module Plutus.Contracts.V2.SimpleMarketplace(
  simpleMarketplacePlutusV2,
  simpleMarketplaceScript,
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
import Cardano.Api.Shelley (PlutusScript (..), PlutusScriptV2)
import Codec.Serialise ( serialise )
import PlutusLedgerApi.V2
import PlutusLedgerApi.V1.Value
import PlutusLedgerApi.V2.Contexts


{-# INLINABLE allScriptInputsCount #-}
allScriptInputsCount:: ScriptContext ->Integer
allScriptInputsCount ctx@(ScriptContext info purpose)=
    foldl (\c txOutTx-> c + countTxOut txOutTx) 0 (txInfoInputs  info)
  where
  countTxOut (TxInInfo _ (TxOut addr _ _ _)) = case addr of { Address cre m_sc -> case cre of
                                                              PubKeyCredential pkh -> 0
                                                              ScriptCredential vh -> 1  } 


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
        Buy       -> traceIfFalse "Multiple script inputs" (allScriptInputsCount  ctx == 1)  && 
                     traceIfFalse "Seller not paid" (assetClassValueOf   (valuePaidTo info pkh) adaAsset >= priceOfAsset)
        Withdraw -> traceIfFalse "Seller Signature Missing" $ txSignedBy info pkh

    where
      sellerPkh= case sellerAddress of { Address cre m_sc -> case cre of
                                                           PubKeyCredential pkh -> Just pkh
                                                           ScriptCredential vh -> Nothing  }
      info  =  scriptContextTxInfo ctx
      adaAsset=AssetClass (adaSymbol,adaToken )

{-# INLINABLE mkWrappedMarket #-}
mkWrappedMarket ::  BuiltinData -> BuiltinData -> BuiltinData -> ()
mkWrappedMarket  d r c = check $ mkMarket (parseData d "Invalid data") (parseData r "Invalid redeemer") (parseData c "Invalid context")
  where
    parseData md s = case fromBuiltinData  md of 
      Just datum -> datum
      _      -> traceError s


simpleMarketValidator = 
            $$(PlutusTx.compile [|| mkWrappedMarket ||])

simpleMarketplaceScript  =  serialiseCompiledCode  simpleMarketValidator


simpleMarketplacePlutusV2 ::  PlutusScript PlutusScriptV2
simpleMarketplacePlutusV2  = PlutusScriptSerialised $ simpleMarketplaceScript