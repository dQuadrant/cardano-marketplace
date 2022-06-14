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
module Plutus.Contracts.V1.MarketplaceOffer(
  offerScriptPlutus,
  offerValidator,
  offerScript,
  OfferRedeemer(..),
  SimpleOffer(..)
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


data OfferRedeemer =  AcceptOffer | CancelOffer
    deriving (Generic,FromJSON,ToJSON,Show,Prelude.Eq)


PlutusTx.makeIsDataIndexed ''OfferRedeemer [('AcceptOffer, 0), ('CancelOffer,1)]


data SimpleOffer=SimpleOffer{
    offererAddress:: Address, -- The Offering address
    tokenName:: TokenName,   -- Token name that is being requested
    policyId :: CurrencySymbol  -- Policy id of the token that is being requested
  } deriving(Show,Generic)


PlutusTx.makeIsDataIndexed ''SimpleOffer [('SimpleOffer, 0)]    

{-# INLINABLE mkOffer #-}
mkOffer ::  SimpleOffer   -> OfferRedeemer -> ScriptContext    -> Bool
mkOffer  ds@SimpleOffer{offererAddress,tokenName,policyId}  action ctx =
  case toPubKeyHash offererAddress of 
    Nothing -> traceError "Script Address in Offerer"
    Just pkh -> case  action of
        AcceptOffer -> traceIfFalse "Multiple script inputs" (allScriptInputsCount  ctx == 1)  && 
                        traceIfFalse "Offerer not paid" (assetClassValueOf   (valuePaidTo info pkh) offerAsset > 0)
        CancelOffer -> traceIfFalse "Offerer Signature Missing" $ txSignedBy info pkh

    where
      info  =  scriptContextTxInfo ctx
      offerAsset=AssetClass (policyId,tokenName )

{-# INLINABLE mkWrappedOffer #-}
mkWrappedOffer ::  BuiltinData -> BuiltinData -> BuiltinData -> ()
mkWrappedOffer  d r c = check $ mkOffer (unsafeFromBuiltinData d) (unsafeFromBuiltinData r) (unsafeFromBuiltinData c)


offerValidator ::   Validator
offerValidator = mkValidatorScript  $
            $$(PlutusTx.compile [|| mkWrappedOffer ||])

offerScript ::   Script
offerScript  =  unValidatorScript  offerValidator

offerScriptBS :: SBS.ShortByteString
offerScriptBS  =  SBS.toShort . LBS.toStrict $ serialise $ offerScript 

offerScriptPlutus  ::  PlutusScript PlutusScriptV1
offerScriptPlutus  = PlutusScriptSerialised $ offerScriptBS