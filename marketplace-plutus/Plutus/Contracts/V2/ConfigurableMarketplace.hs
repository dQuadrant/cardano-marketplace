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

module Plutus.Contracts.V2.ConfigurableMarketplace where

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
import Cardano.Api.Shelley (PlutusScript (..), PlutusScriptV2)
import Codec.Serialise ( serialise )
import Plutus.Contracts.V2.MarketplaceConfig (MarketConfig(..))
import Cardano.Api (IsCardanoEra,BabbageEra,NetworkId, AddressInEra, ShelleyAddr, BabbageEra, Script (PlutusScript), PlutusScriptVersion (PlutusScriptV2), hashScript, PaymentCredential (PaymentCredentialByScript), StakeAddressReference (NoStakeAddress), makeShelleyAddressInEra, makeShelleyAddress)
import qualified Cardano.Api.Shelley
import PlutusTx.Builtins (decodeUtf8)
import PlutusLedgerApi.V2
import PlutusCore.Version (plcVersion100)
import PlutusLedgerApi.V1.Value
import PlutusLedgerApi.V2.Contexts
import Cardano.Api (ShelleyBasedEra(ShelleyBasedEraConway))
import Cardano.Api (ConwayEra)



{-# INLINABLE allScriptInputsCount #-}
allScriptInputsCount:: ScriptContext ->Integer
allScriptInputsCount ctx@(ScriptContext info purpose)=
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
        Buy       -> traceIfFalse "ConfigurableMarket: Multiple script inputs" (allScriptInputsCount  ctx == 1)  &&
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

{-# INLINABLE mkWrappedConfigurableMarket #-}
mkWrappedConfigurableMarket :: MarketConstructor ->  BuiltinData -> BuiltinData -> BuiltinData -> BuiltinUnit
mkWrappedConfigurableMarket constructor   d r c = check $ mkConfigurableMarket constructor (parseData d "ConfigurableMarket: Invalid data") (parseData r "ConfigurableMarket: Invalid redeemer") (unsafeFromBuiltinData c)
  where
    parseData d s = case fromBuiltinData  d of
      Just d -> d
      _      -> traceError s


configurableMarketValidator constructor = 
    $$(PlutusTx.compile [|| mkWrappedConfigurableMarket ||])
            `unsafeApplyCode` PlutusTx.liftCode plcVersion100 constructor


configurableMarketScript constructor  =  serialiseCompiledCode   $ configurableMarketValidator constructor

configurableMarketPlutusScript :: MarketConstructor -> PlutusScript PlutusScriptV2
configurableMarketPlutusScript  constructor = Cardano.Api.Shelley.PlutusScriptSerialised $ configurableMarketScriptBS
  where
  configurableMarketScriptBS  =   configurableMarketScript  constructor