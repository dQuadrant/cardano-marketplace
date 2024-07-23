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
  marketConfigPlutusScriptSuperLazy,
  marketConfigScript,
  MarketConfig(..)
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
import qualified PlutusTx.Builtins.Internal as BI

data MarketConfig=MarketConfig{
    marketOwner :: Address,
    marketFeeReceiverAddress:: Address, 
    marketFee:: Integer  
  } deriving(Show,Generic)

PlutusTx.makeIsDataIndexed ''MarketConfig [('MarketConfig, 0)]    

{-# INLINABLE parseData #-}
parseData ::FromData a =>  BuiltinData -> BuiltinString -> a
parseData d s = case fromBuiltinData  d of
  Just d -> d
  _      -> traceError s

{-# INLINABLE constrArgs #-}
constrArgs :: BuiltinData -> BI.BuiltinList BuiltinData
constrArgs bd = BI.snd (BI.unsafeDataAsConstr bd)

{-# INLINABLE marketConfigScriptBS #-}
marketConfigScriptBS :: SerialisedScript -> SBS.ShortByteString
marketConfigScriptBS  script =  SBS.toShort . LBS.toStrict $ serialise $ script

{-# INLINABLE mkMarketConfig #-}
mkMarketConfig ::  MarketConfig   -> ScriptContext    -> Bool
mkMarketConfig  MarketConfig{marketOwner}  ctx = 
  case marketOwner of {Address cre m_sc -> case cre of
    PubKeyCredential pkh ->traceIfFalse "Missing owner signature" (txSignedBy info pkh)
    ScriptCredential vh -> traceError "NotOperator"  }
  where
    info  =  scriptContextTxInfo ctx

{-# INLINABLE mkMarketConfigSuperLazy #-}
mkMarketConfigSuperLazy :: MarketConfig -> [PubKeyHash] -> Bool
mkMarketConfigSuperLazy MarketConfig{marketOwner} signatures = 
  case marketOwner of {Address cre m_sc -> case cre of
    PubKeyCredential pkh ->traceIfFalse "Missing owner signature" (pkh `elem` signatures)
    ScriptCredential vh -> traceError "NotOperator"  }

{-# INLINABLE mkWrappedMarketConfig #-}
mkWrappedMarketConfig ::  BuiltinData -> BuiltinData -> BuiltinData -> BuiltinUnit
mkWrappedMarketConfig  d r c = 
  check $ mkMarketConfig (parseData d "Invalid data") (unsafeFromBuiltinData c)

{-# INLINABLE mkWrappedMarketConfigSuperLazy #-}
mkWrappedMarketConfigSuperLazy :: BuiltinData -> BuiltinData -> BuiltinData -> BuiltinUnit
mkWrappedMarketConfigSuperLazy d r c = 
  check $ mkMarketConfigSuperLazy (parseData d "Invalid data") signatures 
  where 
    context = constrArgs c
    
    txInfoData :: BuiltinData 
    txInfoData = BI.head context

    lazyTxInfo :: BI.BuiltinList BuiltinData
    lazyTxInfo = constrArgs txInfoData

    signatures :: [PubKeyHash]
    signatures = parseData 
      (BI.head $ BI.tail $ BI.tail $ BI.tail $ BI.tail $ BI.tail $ BI.tail $ BI.tail $ BI.tail lazyTxInfo) 
      "txInfoSignatories: Invalid [PubKeyHash] type"


marketConfigValidator =  
  $$(PlutusTx.compile [|| mkWrappedMarketConfig ||])

marketConfigValidatorSuperLazy = 
  $$(PlutusTx.compile [|| mkWrappedMarketConfigSuperLazy ||])

marketConfigScript  =  serialiseCompiledCode  marketConfigValidator
marketConfigScriptSuperLazy = serialiseCompiledCode  marketConfigValidatorSuperLazy

marketConfigPlutusScript  = PlutusScript PlutusScriptV2  $ Cardano.Api.Shelley.PlutusScriptSerialised $ marketConfigScriptBS marketConfigScript

marketConfigPlutusScriptSuperLazy  = PlutusScript PlutusScriptV2  $ Cardano.Api.Shelley.PlutusScriptSerialised $ marketConfigScriptBS marketConfigScriptSuperLazy