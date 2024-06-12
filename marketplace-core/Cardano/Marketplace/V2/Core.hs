{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeApplications #-}

module Cardano.Marketplace.V2.Core where

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

marketAddressShelley :: NetworkId -> Address ShelleyAddr
marketAddressShelley network = makeShelleyAddress network scriptCredential' NoStakeAddress

scriptCredential' :: PaymentCredential
scriptCredential' = PaymentCredentialByScript marketHash
  where
    marketHash = hashScript marketScript
    marketScript = PlutusScript PlutusScriptV2 simpleMarketplacePlutusV2

marketAddressInEra :: NetworkId -> AddressInEra ConwayEra
marketAddressInEra network = makeShelleyAddressInEra ShelleyBasedEraConway network scriptCredential' NoStakeAddress

createV2SaleDatum :: AddressInEra ConwayEra -> Integer -> HashableScriptData
createV2SaleDatum sellerAddr costOfAsset =
  -- Convert AddressInEra to Plutus.Address
  let plutusAddr =  toPlutusAddress sellerAddrShelley
      sellerAddrShelley = case sellerAddr of {
         AddressInEra atie ad -> case ad of
          addr@(ShelleyAddress net cre sr )-> addr  
          _  -> error "Byron era address Not supported"

          }
      datum = SimpleSale plutusAddr costOfAsset
   in unsafeHashableScriptData $  fromPlutusData $ toData datum

sellBuilder :: AddressInEra ConwayEra ->  Value -> Integer -> AddressInEra  ConwayEra  -> TxBuilder
sellBuilder contractAddr saleItem cost  sellerAddr 
  = txPayToScriptWithData contractAddr saleItem (createV2SaleDatum sellerAddr cost)

withdrawRedeemer = ( unsafeHashableScriptData $ fromPlutusData$ toData Marketplace.Withdraw)
buyRedeemer = ( unsafeHashableScriptData $ fromPlutusData$ toData Marketplace.Buy)

buyTokenBuilder ::  HasChainQueryAPI api => 
  Maybe TxIn -> 
  TxIn -> 
  PlutusScript PlutusScriptV2 -> 
  Maybe (AddressInEra ConwayEra, Integer, TxIn) -> 
  Kontract api w FrameworkError TxBuilder
buyTokenBuilder refTxIn txin script feeInfo = do
  netid<- kGetNetworkId
  (tin, tout) <- resolveTxIn txin
  kWrapParser $ buyTokenBuilder' script buyRedeemer  netid refTxIn txin tout feeInfo

withdrawTokenBuilder ::  HasChainQueryAPI api => Maybe TxIn -> TxIn  -> PlutusScript PlutusScriptV2 -> Kontract api w FrameworkError TxBuilder
withdrawTokenBuilder refTxIn txin script = do
  netid<- kGetNetworkId
  (tin, tout) <- resolveTxIn txin
  kWrapParser $ withdrawTokenBuilder' script withdrawRedeemer netid refTxIn txin tout