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
module Plutus.Contracts.V2.SimpleMarketplace(
  simpleMarketplacePlutus,
  simpleMarketValidator,
  simpleMarketScript,
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
import Plutus.V2.Ledger.Api
import Plutus.V2.Ledger.Contexts (valuePaidTo, ownHash, valueLockedBy, findOwnInput, findDatum,txSignedBy)
import qualified Data.ByteString.Short as SBS
import qualified Data.ByteString.Lazy  as LBS
import Cardano.Api.Shelley (PlutusScript (..), PlutusScriptV1)
import Codec.Serialise ( serialise )
import Plutus.V1.Ledger.Value (assetClassValueOf, AssetClass (AssetClass))


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
mkWrappedMarket  d r c = check $ mkMarket (unsafeFromBuiltinData d) (unsafeFromBuiltinData r) (unsafeFromBuiltinData c)


simpleMarketValidator ::   Validator
simpleMarketValidator = mkValidatorScript  $
            $$(PlutusTx.compile [|| mkWrappedMarket ||])

simpleMarketScript ::   Script
simpleMarketScript  =  unValidatorScript  simpleMarketValidator

marketScriptSBS :: SBS.ShortByteString
marketScriptSBS  =  SBS.toShort . LBS.toStrict $ serialise $ simpleMarketScript 

simpleMarketplacePlutus ::  PlutusScript PlutusScriptV1
simpleMarketplacePlutus  = PlutusScriptSerialised $ marketScriptSBS