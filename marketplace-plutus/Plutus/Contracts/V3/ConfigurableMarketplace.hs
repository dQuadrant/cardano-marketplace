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

module Plutus.Contracts.V3.ConfigurableMarketplace where

import GHC.Generics (Generic)
import PlutusTx.Prelude
import Prelude(Show )
import qualified Prelude
import  PlutusTx hiding( txOutDatum)
import Data.Aeson (FromJSON, ToJSON)
import qualified PlutusTx.AssocMap as AssocMap
import qualified Data.Bifunctor
import qualified Data.ByteString.Short as SBS
import qualified Data.ByteString.Lazy  as LBS
import Cardano.Api.Shelley (PlutusScript (..), PlutusScriptV3)
import Codec.Serialise ( serialise )
import Cardano.Api (IsCardanoEra,BabbageEra,NetworkId, AddressInEra, ShelleyAddr, BabbageEra, Script (PlutusScript), PlutusScriptVersion (PlutusScriptV3), hashScript, PaymentCredential (PaymentCredentialByScript), StakeAddressReference (NoStakeAddress), makeShelleyAddressInEra, makeShelleyAddress, ShelleyBasedEra (..))
import qualified Cardano.Api.Shelley
import PlutusTx.Builtins (decodeUtf8)
import PlutusLedgerApi.V3
import PlutusCore.Version (plcVersion110)
import qualified PlutusTx.Builtins.Internal as BI
import PlutusLedgerApi.V1.Value
import PlutusLedgerApi.V3.Contexts
import Cardano.Api (ShelleyBasedEra(ShelleyBasedEraBabbage))
import Plutus.Contracts.V3.MarketplaceConfig (MarketConfig(..))
import Cardano.Api (ConwayEra)



{-# INLINABLE allScriptInputsCount #-}
allScriptInputsCount:: TxInfo ->Integer
allScriptInputsCount info=
    foldl (\c txOutTx-> c + countTxOut txOutTx) 0 (txInfoInputs  info)
  where
  countTxOut (TxInInfo _ (TxOut addr _ _ _)) = case addr of { Address cre m_sc -> case cre of
                                                              PubKeyCredential pkh -> 0
                                                              ScriptCredential vh -> 1  }
getConfigFromInfo :: ScriptHash -> TxInfo  -> MarketConfig
getConfigFromInfo configScriptValHash info = findRightDatum (txInfoReferenceInputs info)
  where
    findRightDatum [] =traceError "ConfigurableMarket: Missing referenceInput data"
    findRightDatum (TxInInfo _ (TxOut (Address cre m_sc) _ (OutputDatum (Datum d)) _):other) =
      case cre of
          PubKeyCredential pkh -> findRightDatum other
          ScriptCredential vh ->  if  vh == configScriptValHash
                                    then ( case fromBuiltinData  d of
                                            Just bData  -> bData
                                            _       -> traceError "ConfigurableMarket: Invalid reference configData"

                                      )
                                    else findRightDatum other
    findRightDatum (_:other) = findRightDatum other

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

data MarketConstructor =MarketConstructor {
  configValidatorytHash :: ScriptHash
}
PlutusTx.makeLift  ''MarketConstructor

data SimpleSale=SimpleSale{
    sellerAddress:: Address, -- The main seller Note that we are using address 
    priceOfAsset:: Integer  -- cost of the value in it
  } deriving(Show,Generic)


PlutusTx.makeIsDataIndexed ''SimpleSale [('SimpleSale, 0)]

{-# INLINABLE mkConfigurableMarket #-}
mkConfigurableMarket   :: MarketConstructor -> SimpleSale   -> MarketRedeemer -> ScriptContext    -> Bool
mkConfigurableMarket  MarketConstructor{configValidatorytHash} ds@SimpleSale{sellerAddress,priceOfAsset}  action ctx =
    case  action of
        Buy       -> traceIfFalse "ConfigurableMarket: Multiple script inputs" (allScriptInputsCount  info == 1)  &&
                     traceIfFalse "ConfigurableMarket: Seller not paid" (assetClassValueOf   (valuePaidTo info sellerPkh) adaAsset >= priceOfAsset) &&
                     traceIfFalse "ConfigurableMarket: Market fee not paid" (assetClassValueOf (valuePaidTo info feePkh ) adaAsset >= fee )
        Withdraw -> traceIfFalse "ConfigurableMarket: Seller Signature Missing" $ txSignedBy info sellerPkh

    where
      (MarketConfig _ feeAddr fee)  = getConfigFromInfo configValidatorytHash info
      toPkh addr msg = case addr of { Address cre m_sc -> case cre of
                                                  PubKeyCredential pkh ->  pkh
                                                  ScriptCredential vh -> traceError msg  }
      sellerPkh = toPkh sellerAddress "ConfigurableMarket: Invalid sellerAddr"
      feePkh = toPkh feeAddr "ConfigurableMarket: Invalid operatorAddr"
      info  =  scriptContextTxInfo ctx
      adaAsset=AssetClass (adaSymbol,adaToken )


{-# INLINABLE expectSpending #-}
expectSpending :: FromData a => ScriptContext -> a
expectSpending ctx =  case (scriptContextScriptInfo ctx ) of
        SpendingScript outRef datum -> case datum of 
          Just d ->  case fromBuiltinData  (getDatum d) of
            Nothing -> traceError "Invalid datum format"
            Just v -> v
          _ -> traceError "Missing datum" 
        _ -> traceError "Script used for other than spending" 

{-# INLINABLE mkWrappedConfigurableMarket #-}
mkWrappedConfigurableMarket :: MarketConstructor -> BuiltinData -> BuiltinUnit
mkWrappedConfigurableMarket constructor  ctx = check $ mkConfigurableMarket constructor 
          (expectSpending context) 
          redeemer context
  where
    redeemer = parseData (getRedeemer $ scriptContextRedeemer context) "Invalid redeemer"
    context = parseData c "Invalid Context"

{-# INLINABLE mkConfigurableMarketLazy #-}
mkConfigurableMarketLazy :: MarketConstructor -> SimpleSale   -> MarketRedeemer -> TxInfo -> Bool
mkConfigurableMarketLazy  MarketConstructor{configValidatorytHash} ds@SimpleSale{sellerAddress,priceOfAsset}  action info =
    case  action of
        Buy       -> traceIfFalse "ConfigurableMarket: Multiple script inputs" (allScriptInputsCount  info == 1)  &&
                     traceIfFalse "ConfigurableMarket: Seller not paid" (assetClassValueOf   (valuePaidTo info sellerPkh) adaAsset >= priceOfAsset) &&
                     traceIfFalse "ConfigurableMarket: Market fee not paid" (assetClassValueOf (valuePaidTo info feePkh ) adaAsset >= fee )
        Withdraw -> traceIfFalse "ConfigurableMarket: Seller Signature Missing" $ txSignedBy info sellerPkh

    where
      (MarketConfig _ feeAddr fee)  = getConfigFromInfo configValidatorytHash info
      toPkh addr msg = case addr of { Address cre m_sc -> case cre of
                                                  PubKeyCredential pkh ->  pkh
                                                  ScriptCredential vh -> traceError msg  }
      sellerPkh = toPkh sellerAddress "ConfigurableMarket: Invalid sellerAddr"
      feePkh = toPkh feeAddr "ConfigurableMarket: Invalid operatorAddr"
      adaAsset=AssetClass (adaSymbol,adaToken )

{-# INLINABLE mkWrappedConfigurableMarketLazy #-}
mkWrappedConfigurableMarketLazy :: MarketConstructor -> BuiltinData -> BuiltinUnit
mkWrappedConfigurableMarketLazy constructor ctx = check $ mkConfigurableMarketLazy constructor 
          datum 
          redeemer info
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

configurableMarketValidator constructor = 
    $$(PlutusTx.compile [|| mkWrappedConfigurableMarket ||])
            `unsafeApplyCode` PlutusTx.liftCode plcVersion110 constructor

configurableMarketValidatorLazy constructor = 
    $$(PlutusTx.compile [|| mkWrappedConfigurableMarketLazy ||])
            `unsafeApplyCode` PlutusTx.liftCode plcVersion110 constructor

configurableMarketScript constructor  =  serialiseCompiledCode   $ configurableMarketValidator constructor
configurableMarketScriptLazy constructor  =  serialiseCompiledCode   $ configurableMarketValidatorLazy constructor

configurableMarketPlutusScript :: MarketConstructor -> PlutusScript PlutusScriptV3
configurableMarketPlutusScript  constructor = Cardano.Api.Shelley.PlutusScriptSerialised $ (configurableMarketScript  constructor) 

configurableMarketPlutusScriptLazy :: MarketConstructor -> PlutusScript PlutusScriptV3
configurableMarketPlutusScriptLazy  constructor = Cardano.Api.Shelley.PlutusScriptSerialised $ (configurableMarketScriptLazy  constructor) 