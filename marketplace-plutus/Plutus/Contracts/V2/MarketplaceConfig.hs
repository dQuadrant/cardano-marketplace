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
module Plutus.Contracts.V2.MarketplaceConfig(
  marketConfigPlutusScript,
  marketConfigValidator,
  marketConfigScript,
  MarketConfig(..),
  marketConfigAddressShelly,
  marketConfigAddress,
  marketConfigScriptCredential
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
import Codec.Serialise ( serialise )
import Plutus.V1.Ledger.Value (assetClassValueOf, AssetClass (AssetClass))
import Cardano.Api (IsCardanoEra,BabbageEra,NetworkId, AddressInEra, ShelleyAddr, BabbageEra, Script (PlutusScript), PlutusScriptVersion (PlutusScriptV2), hashScript, PaymentCredential (PaymentCredentialByScript), StakeAddressReference (NoStakeAddress), makeShelleyAddressInEra, makeShelleyAddress)
import qualified Cardano.Api.Shelley


data MarketConfig=MarketConfig{
    marketOwner :: Address,
    marketFeeReceiverAddress:: Address, 
    marketFee:: Integer  
  } deriving(Show,Generic)

PlutusTx.makeIsDataIndexed ''MarketConfig [('MarketConfig, 0)]    

{-# INLINABLE mkMarketConfig #-}
mkMarketConfig ::  MarketConfig   -> ScriptContext    -> Bool
mkMarketConfig  MarketConfig{marketOwner}  ctx = 
  case marketOwner of {Address cre m_sc -> case cre of
    PubKeyCredential pkh ->traceIfFalse "Missing owner signature" (txSignedBy info pkh)
    ScriptCredential vh -> traceError "NotOperator"  }
  where
    info  =  scriptContextTxInfo ctx


{-# INLINABLE mkWrappedMarketConfig #-}
mkWrappedMarketConfig ::  BuiltinData -> BuiltinData -> BuiltinData -> ()
mkWrappedMarketConfig  d r c = check $ mkMarketConfig (parseData d "Invalid data") (unsafeFromBuiltinData c)
  where
    parseData md s = case fromBuiltinData  d of 
      Just d -> d
      _      -> traceError s


marketConfigValidator ::   Validator
marketConfigValidator = mkValidatorScript  
            $$(PlutusTx.compile [|| mkWrappedMarketConfig ||])

marketConfigScript ::   Plutus.V2.Ledger.Api.Script
marketConfigScript  =  unValidatorScript  marketConfigValidator



marketConfigPlutusScript  = PlutusScript PlutusScriptV2  $ Cardano.Api.Shelley.PlutusScriptSerialised $ marketConfigScriptBS
  where
  marketConfigScriptBS :: SBS.ShortByteString
  marketConfigScriptBS  =  SBS.toShort . LBS.toStrict $ serialise $ marketConfigScript 

marketConfigAddressShelly :: NetworkId -> Cardano.Api.Shelley.Address ShelleyAddr
marketConfigAddressShelly network = makeShelleyAddress network marketConfigScriptCredential NoStakeAddress


marketConfigAddress :: IsCardanoEra  BabbageEra  => NetworkId -> AddressInEra BabbageEra 
marketConfigAddress network = makeShelleyAddressInEra network marketConfigScriptCredential NoStakeAddress


marketConfigScriptCredential :: Cardano.Api.Shelley.PaymentCredential
marketConfigScriptCredential = PaymentCredentialByScript $ hashScript marketConfigPlutusScript

marketConfigValidatorHash :: Cardano.Api.Shelley.PaymentCredential
marketConfigValidatorHash = PaymentCredentialByScript $ hashScript marketConfigPlutusScript
