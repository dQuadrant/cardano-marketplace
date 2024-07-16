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
import qualified Data.ByteString.Short as SBS
import qualified Data.ByteString.Lazy  as LBS
import Codec.Serialise ( serialise )
import Cardano.Api (IsCardanoEra,BabbageEra,NetworkId, AddressInEra, ShelleyAddr, BabbageEra, Script (PlutusScript), PlutusScriptVersion (PlutusScriptV2), hashScript, PaymentCredential (PaymentCredentialByScript), StakeAddressReference (NoStakeAddress), makeShelleyAddressInEra, makeShelleyAddress, ConwayEra)
import qualified Cardano.Api.Shelley
import PlutusLedgerApi.V2
import PlutusLedgerApi.V2.Contexts


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
mkWrappedMarketConfig ::  BuiltinData -> BuiltinData -> BuiltinData -> BuiltinUnit
mkWrappedMarketConfig  d r c = 
  check $ mkMarketConfig (parseData d "Invalid data") (unsafeFromBuiltinData c)
  where
    parseData md s = case fromBuiltinData  d of 
      Just d -> d
      _      -> traceError s


marketConfigValidator =  
            $$(PlutusTx.compile [|| mkWrappedMarketConfig ||])

marketConfigScript  =  serialiseCompiledCode  marketConfigValidator


marketConfigPlutusScript  = PlutusScript PlutusScriptV2  $ Cardano.Api.Shelley.PlutusScriptSerialised $ marketConfigScriptBS
  where
  marketConfigScriptBS :: SBS.ShortByteString
  marketConfigScriptBS  =  SBS.toShort . LBS.toStrict $ serialise $ marketConfigScript 

marketConfigAddressShelly :: NetworkId -> Cardano.Api.Shelley.Address ShelleyAddr
marketConfigAddressShelly network = makeShelleyAddress network marketConfigScriptCredential NoStakeAddress


marketConfigAddress ::  NetworkId -> AddressInEra ConwayEra 
marketConfigAddress network = makeShelleyAddressInEra Cardano.Api.Shelley.ShelleyBasedEraConway network marketConfigScriptCredential NoStakeAddress


marketConfigScriptCredential :: Cardano.Api.Shelley.PaymentCredential
marketConfigScriptCredential = PaymentCredentialByScript $ hashScript marketConfigPlutusScript

marketConfigValidatorHash :: Cardano.Api.Shelley.PaymentCredential
marketConfigValidatorHash = PaymentCredentialByScript $ hashScript marketConfigPlutusScript