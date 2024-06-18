{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeApplications #-}

module Cardano.Marketplace.SimpleMarketplace where

import Cardano.Api
import Cardano.Api.Shelley (ProtocolParameters, ReferenceScript (ReferenceScriptNone), fromPlutusData, scriptDataToJsonDetailedSchema, toPlutusData, Address (ShelleyAddress))
import qualified Cardano.Api.Shelley as Shelley
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers
import Cardano.Kuber.Util
import Cardano.Marketplace.Common.TextUtils
import Cardano.Marketplace.Common.TransactionUtils
import Codec.Serialise (serialise)
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.Text as Aeson
import qualified Data.Map as Map
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Lazy as TLE
import Plutus.Contracts.V2.SimpleMarketplace hiding (Withdraw)
import qualified Plutus.Contracts.V2.SimpleMarketplace as SMP
import qualified Plutus.Contracts.V2.ConfigurableMarketplace as Config
import qualified Debug.Trace as Debug
import Data.Functor ((<&>))
import Control.Exception (throw)
import qualified Data.Set as Set
import qualified Plutus.Contracts.V2.SimpleMarketplace as Marketplace
import PlutusLedgerApi.V2 (toData, dataToBuiltinData, FromData (fromBuiltinData))

data SimpleMarketHelper = SimpleMarketHelper {
    simpleMarketScript :: TxPlutusScript
  , makeSaleDatum :: AddressInEra ConwayEra -> Integer -> HashableScriptData
  , withdrawRedeemer :: HashableScriptData
  , buyRedeemer :: HashableScriptData
}

sellBuilder :: SimpleMarketHelper -> AddressInEra ConwayEra ->  Value -> Integer -> AddressInEra  ConwayEra  -> TxBuilder
sellBuilder smHelper marketAddr saleItem cost  sellerAddr 
  = txPayToScriptWithData marketAddr saleItem (makeSaleDatum smHelper sellerAddr cost)

buyTokenBuilder ::  HasChainQueryAPI api => 
  SimpleMarketHelper ->
  Maybe TxIn -> 
  TxIn -> 
  Maybe (AddressInEra ConwayEra, Integer, TxIn) -> 
  Kontract api w FrameworkError TxBuilder
buyTokenBuilder mHelper refTxIn txin  feeInfo = do
  netid<- kGetNetworkId
  (tin, tout) <- resolveTxIn txin
  kWrapParser $ buyTokenBuilder' (simpleMarketScript mHelper ) (buyRedeemer mHelper )  netid refTxIn txin tout feeInfo

withdrawTokenBuilder ::  HasChainQueryAPI api => SimpleMarketHelper -> Maybe TxIn -> TxIn  -> Kontract api w FrameworkError TxBuilder
withdrawTokenBuilder mHelper refTxIn txin  = do
  netid<- kGetNetworkId
  (tin, tout) <- resolveTxIn txin
  kWrapParser $ withdrawTokenBuilder' (simpleMarketScript mHelper ) (withdrawRedeemer mHelper) netid refTxIn txin tout