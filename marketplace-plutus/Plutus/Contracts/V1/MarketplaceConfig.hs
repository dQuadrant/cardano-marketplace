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
module Plutus.Contracts.V1.SimpleMarketplace(
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
import Plutus.V1.Ledger.Api
import Plutus.V1.Ledger.Value ( assetClassValue, geq, AssetClass(..),CurrencySymbol(..),TokenName(..), assetClassValueOf )
import Plutus.V1.Ledger.Contexts (valuePaidTo, ownHash, valueLockedBy, findOwnInput, findDatum,txSignedBy)
import Plutus.V1.Ledger.Address (toPubKeyHash, scriptHashAddress, toValidatorHash)
import Plutus.V1.Ledger.Scripts (getScriptHash, ScriptHash (ScriptHash))
import qualified Data.ByteString.Short as SBS
import qualified Data.ByteString.Lazy  as LBS
import Cardano.Api.Shelley (PlutusScript (..), PlutusScriptV1)
import Codec.Serialise ( serialise )


{-# INLINABLE allScriptInputsCount #-}
allScriptInputsCount:: ScriptContext ->Integer
allScriptInputsCount ctx@(ScriptContext info purpose)=
    foldl (\c txOutTx-> c + countTxOut txOutTx) 0 (txInfoInputs  info)
  where
  countTxOut (TxInInfo _ (TxOut addr _ _)) = if isJust (toValidatorHash addr) then 1 else 0


data MarketConfig=MarketConfig{
    marketOwner :: Address,
    marketFeeAddress:: Address, -- The main seller Note that we are using address 
    marketFee:: Integer  -- cost of the value in it
  } deriving(Show,Generic)


PlutusTx.makeIsDataIndexed ''MarketConfig [('MarketConfig, 0)]    

{-# INLINABLE mkMarket #-}
mkMarketConfig ::  MarketConfig   -> ScriptContext    -> Bool
mkMarketConfig  MarketConfig{marketFeeAddress,marketFee}  ctx = 
  case marketOwner of {Address cre m_sc -> case cre of
    PubKeyCredential pkh ->traceIfFalse "Missing owner signature" (txSignedBy info pkh)
    ScriptCredential vh -> traceError "NotOperator"  }
  where
    operatorPkh= case sellerAddress of { Address cre m_sc -> case cre of
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
simpleMarketplacePlutus  =  PlutusScriptSerialised $ marketScriptSBS