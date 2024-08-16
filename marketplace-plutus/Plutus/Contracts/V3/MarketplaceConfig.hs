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
module Plutus.Contracts.V3.MarketplaceConfig(
  marketConfigPlutusScript,
  marketConfigPlutusScriptLazy,
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
import Cardano.Api (IsCardanoEra,NetworkId, AddressInEra, ShelleyAddr, Script (PlutusScript), PlutusScriptVersion (PlutusScriptV3), hashScript, PaymentCredential (PaymentCredentialByScript), StakeAddressReference (NoStakeAddress), makeShelleyAddressInEra, makeShelleyAddress, ConwayEra)
import qualified Cardano.Api.Shelley
import PlutusLedgerApi.V3
import PlutusLedgerApi.V3.Contexts
import qualified PlutusTx.Builtins.Internal as BI


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

{-# INLINABLE expectSpending #-}
expectSpending :: FromData a => ScriptContext -> a
expectSpending ctx =  case (scriptContextScriptInfo ctx ) of
        SpendingScript outRef datum -> case datum of 
          Just d ->  case fromBuiltinData  (getDatum d) of
            Nothing -> traceError "Invalid datum format"
            Just v -> v
          _ -> traceError "Missing datum" 
        _ -> traceError "Script used for other than spending" 


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

{-# INLINABLE mkWrappedMarketConfig #-}
mkWrappedMarketConfig ::   BuiltinData -> BuiltinUnit
mkWrappedMarketConfig   ctx = 
  check $ mkMarketConfig (expectSpending context) context
  where
    context = parseData ctx "Invalid Context"


{-# INLINABLE mkMarketConfigLazy #-}
mkMarketConfigLazy ::  MarketConfig   -> TxInfo    -> Bool
mkMarketConfigLazy  MarketConfig{marketOwner}  info = 
  case marketOwner of {Address cre m_sc -> case cre of
    PubKeyCredential pkh ->traceIfFalse "Missing owner signature" (txSignedBy info pkh)
    ScriptCredential vh -> traceError "NotOperator"  }

{-# INLINABLE mkMarketConfigSuperLazy #-}
mkMarketConfigSuperLazy :: MarketConfig -> [PubKeyHash] -> Bool 
mkMarketConfigSuperLazy MarketConfig{marketOwner} signatures = 
  case marketOwner of {Address cre m_sc -> case cre of
    PubKeyCredential pkh ->traceIfFalse "Missing owner signature" (pkh `elem` signatures)
    ScriptCredential vh -> traceError "NotOperator"  }

{-# INLINABLE mkWrappedMarketConfigLazy #-}
mkWrappedMarketConfigLazy ::   BuiltinData -> BuiltinUnit
mkWrappedMarketConfigLazy ctx = 
  check $ mkMarketConfigLazy datum info
  where
    context = constrArgs ctx

    redeemerFollowedByScriptInfo :: BI.BuiltinList BuiltinData
    redeemerFollowedByScriptInfo = BI.tail context

    scriptInfoData :: BuiltinData
    scriptInfoData = BI.head (BI.tail redeemerFollowedByScriptInfo)

    txInfoData :: BuiltinData 
    txInfoData = BI.head context

    datumData :: BuiltinData
    datumData = BI.head (constrArgs (BI.head (BI.tail (constrArgs scriptInfoData))))

    datum :: MarketConfig
    datum = parseData (getDatum (unsafeFromBuiltinData datumData)) "Invalid Datum Type"

    info :: TxInfo 
    info = parseData txInfoData "Invalid TxInfo Type"

{-# INLINABLE mkWrappedMarketConfigSuperLazy #-}
mkWrappedMarketConfigSuperLazy :: BuiltinData -> BuiltinUnit
mkWrappedMarketConfigSuperLazy ctx = check $ mkMarketConfigSuperLazy datum signatures 
  where 
    context = constrArgs ctx

    redeemerFollowedByScriptInfo :: BI.BuiltinList BuiltinData
    redeemerFollowedByScriptInfo = BI.tail context

    scriptInfoData :: BuiltinData
    scriptInfoData = BI.head (BI.tail redeemerFollowedByScriptInfo)

    txInfoData :: BuiltinData 
    txInfoData = BI.head context

    datumData :: BuiltinData
    datumData = BI.head (constrArgs (BI.head (BI.tail (constrArgs scriptInfoData))))

    datum :: MarketConfig
    datum = parseData (getDatum (unsafeFromBuiltinData datumData)) "Invalid Datum Type"

    lazyTxInfo :: BI.BuiltinList BuiltinData
    lazyTxInfo = constrArgs txInfoData

    signatures :: [PubKeyHash]
    signatures = parseData 
      (BI.head $ BI.tail $ BI.tail $ BI.tail $ BI.tail $ BI.tail $ BI.tail $ BI.tail $ BI.tail lazyTxInfo) 
      "txInfoSignatories: Invalid [PubKeyHash] type"

marketConfigValidator =  
  $$(PlutusTx.compile [|| mkWrappedMarketConfig ||])

marketConfigValidatorLazy =  
  $$(PlutusTx.compile [|| mkWrappedMarketConfigLazy ||])

marketConfigValidatorSuperLazy = 
  $$(PlutusTx.compile [|| mkWrappedMarketConfigSuperLazy ||])


marketConfigScript  =  serialiseCompiledCode  marketConfigValidator
marketConfigScriptLazy = serialiseCompiledCode  marketConfigValidatorLazy
marketConfigScriptSuperLazy = serialiseCompiledCode  marketConfigValidatorSuperLazy

marketConfigPlutusScript  = PlutusScript PlutusScriptV3  $ Cardano.Api.Shelley.PlutusScriptSerialised $ marketConfigScriptBS marketConfigScript 

marketConfigPlutusScriptLazy  = PlutusScript PlutusScriptV3  $ Cardano.Api.Shelley.PlutusScriptSerialised $ marketConfigScriptBS marketConfigScriptLazy 

marketConfigPlutusScriptSuperLazy = PlutusScript PlutusScriptV3  $ Cardano.Api.Shelley.PlutusScriptSerialised $ marketConfigScriptBS marketConfigScriptSuperLazy 