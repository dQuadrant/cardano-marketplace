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
import qualified Plutus.Contracts.V2.ConfigurableMarketplace as V2ConfigurableMarketplace
import qualified Plutus.Contracts.V2.MarketplaceConfig as V2MarketConfig
import PlutusLedgerApi.V2 (toData, dataToBuiltinData, FromData (fromBuiltinData))
import Cardano.Marketplace.SimpleMarketplace
import qualified PlutusLedgerApi.V2 as PlutusV2
import Cardano.Marketplace.ConfigurableMarketplace

simpleMarketV2Helper' :: PlutusScript PlutusScriptV2 -> SimpleMarketHelper
simpleMarketV2Helper' script = SimpleMarketHelper {
    simpleMarketScript = toTxPlutusScript script
  , makeSaleDatum = createV2SaleDatum
  , withdrawRedeemer  = unsafeHashableScriptData $ fromPlutusData$ toData Marketplace.Withdraw
  , buyRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData Marketplace.Buy
}

simpleMarketV2Helper = simpleMarketV2Helper' simpleMarketplacePlutusV2

simpleMarketV2HelperSuperLazy = simpleMarketV2Helper' simpleMarketplacePlutusV2SuperLazy

makeConfigurableMarketV2Helper' :: 
  AddressInEra era -> 
  Integer -> 
  Script PlutusScriptV2 -> 
  (V2ConfigurableMarketplace.MarketConstructor -> PlutusScript PlutusScriptV2) -> 
  ConfigurableMarketHelper
makeConfigurableMarketV2Helper' operatorAddr fee marketConfigScript configurableMarketScript = 
  let operatorAddress = addrInEraToPlutusAddress operatorAddr
      ownerAddress = operatorAddress
      marketConfig = V2MarketConfig.MarketConfig operatorAddress operatorAddress fee
      marketConstructor = V2ConfigurableMarketplace.MarketConstructor  ( 
        PlutusV2.ScriptHash $ PlutusV2.toBuiltin $ serialiseToRawBytes $ hashTxScript  $ TxScriptPlutus mConfigScript)
      mConfigScript = toTxPlutusScript $ marketConfigScript
    in
    ConfigurableMarketHelper {
        cmMarketScript = toTxPlutusScript $ configurableMarketScript marketConstructor 
      , cmConfigScript = mConfigScript
      , cmMakeSaleDatum = createV2SaleDatum
      , cmWithdrawRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData V2ConfigurableMarketplace.Withdraw
      , cmBuyRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData V2ConfigurableMarketplace.Buy
      , cmConfigDatum = unsafeHashableScriptData $ fromPlutusData$ toData marketConfig
      }

makeConfigurableMarketV2Helper :: AddressInEra era -> Integer -> ConfigurableMarketHelper
makeConfigurableMarketV2Helper operatorAddr fee =
  makeConfigurableMarketV2Helper' operatorAddr fee 
  V2MarketConfig.marketConfigPlutusScript 
  V2ConfigurableMarketplace.configurableMarketPlutusScript

makeConfigurableMarketV2HelperSuperLazy :: AddressInEra era -> Integer -> ConfigurableMarketHelper
makeConfigurableMarketV2HelperSuperLazy operatorAddr fee =
  makeConfigurableMarketV2Helper' operatorAddr fee 
  V2MarketConfig.marketConfigPlutusScriptSuperLazy 
  V2ConfigurableMarketplace.configurableMarketPlutusScriptSuperLazy

createV2SaleDatum :: AddressInEra ConwayEra -> Integer -> HashableScriptData
createV2SaleDatum sellerAddr costOfAsset =
  -- Convert  to Plutus.Address
  let plutusAddr =  addrInEraToPlutusAddress sellerAddr
      datum = SimpleSale plutusAddr costOfAsset
   in unsafeHashableScriptData $  fromPlutusData $ toData datum