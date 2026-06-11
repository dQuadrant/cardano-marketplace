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
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers
import Cardano.Kuber.Util
import Cardano.Marketplace.Artifacts
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
import GHC.IO (unsafePerformIO)

simpleMarketV2Helper' :: (HasChainQueryAPI api) => PlutusScript PlutusScriptV2 -> SimpleMarketHelper api w 
simpleMarketV2Helper' script = SimpleMarketHelper {
    simpleMarketScript = toTxPlutusScript script
  , sell = placeOnSell
  , buy = buyf
  , buyWithRefScript = buyFromMarketWithRefScript
  , withdraw = withdrawf
  , withdrawWithRefScript = withdrawFromMarketWithRefScript
}
  where 
    buyf buyTxIn =  buyFromMarket buyTxIn script
    withdrawf withdrawTxIn = withdrawFromMarket withdrawTxIn script

buyRedeemer :: HashableScriptData
buyRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData Marketplace.Buy

withdrawRedeemer :: HashableScriptData
withdrawRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData Marketplace.Withdraw

buyFromMarket spendTxIn script = do
  (tin, tout) <- resolveTxIn spendTxIn 
  kWrapParser $ Right $ buyFromMarket' tin tout script buyRedeemer

withdrawFromMarket withdrawTxIn script = do
  (tin, tout) <- resolveTxIn withdrawTxIn
  kWrapParser $ Right $ withdrawFromMarket' tin tout script withdrawRedeemer

placeOnSell marketAddr saleItem cost sellerAddress = 
  kWrapParser $ Right $ placeOnSell' marketAddr saleItem (createV2SaleDatum sellerAddress cost)

buyFromMarketWithRefScript spendTxIn refTxIn = do
  (tin, tout) <- resolveTxIn spendTxIn 
  kWrapParser $ Right $ buyFromMarketWithRefScript' tin refTxIn tout buyRedeemer

withdrawFromMarketWithRefScript withdrawTxIn refTxIn = do
  (tin, tout) <- resolveTxIn withdrawTxIn 
  kWrapParser $ Right $ withdrawFromMarketWithRefScript' tin refTxIn tout withdrawRedeemer 

simpleMarketV2Helper :: SimpleMarketHelper ChainConnectInfo w 
simpleMarketV2Helper = unsafePerformIO $ simpleMarketV2Helper' <$> loadSimpleMarketV2

simpleMarketV2HelperSuperLazy :: SimpleMarketHelper ChainConnectInfo w 
simpleMarketV2HelperSuperLazy = unsafePerformIO $ simpleMarketV2Helper' <$> loadSimpleMarketV2SuperLazy

makeConfigurableMarketV2Helper' :: 
  AddressInEra era -> 
  Integer -> 
  PlutusScript PlutusScriptV2 ->
  PlutusScript PlutusScriptV2 ->
  ConfigurableMarketHelper
makeConfigurableMarketV2Helper' operatorAddr fee marketConfigScript configurableMarketScript = 
  let operatorAddress = addrInEraToPlutusAddress operatorAddr
      ownerAddress = operatorAddress
      marketConfig = V2MarketConfig.MarketConfig operatorAddress operatorAddress fee
      marketConstructor = V2ConfigurableMarketplace.MarketConstructor  ( 
        PlutusV2.toBuiltin $ serialiseToRawBytes $ hashTxScript  $ TxScriptPlutus mConfigScript)
      mConfigScript = toTxPlutusScript marketConfigScript
    in
    ConfigurableMarketHelper {
        cmMarketScript = toTxPlutusScript configurableMarketScript
      , cmConfigScript = mConfigScript
      , cmMakeSaleDatum = createV2SaleDatum
      , cmWithdrawRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData V2ConfigurableMarketplace.Withdraw
      , cmBuyRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData V2ConfigurableMarketplace.Buy
      , cmConfigDatum = unsafeHashableScriptData $ fromPlutusData$ toData marketConfig
      }

makeConfigurableMarketV2Helper :: AddressInEra era -> Integer -> ConfigurableMarketHelper
makeConfigurableMarketV2Helper operatorAddr fee =
  unsafePerformIO $ do
    configScript <- loadMarketConfigV2
    marketScript <- loadConfigurableMarketV2
    pure $ makeConfigurableMarketV2Helper' operatorAddr fee configScript marketScript

makeConfigurableMarketV2HelperSuperLazy :: AddressInEra era -> Integer -> ConfigurableMarketHelper
makeConfigurableMarketV2HelperSuperLazy operatorAddr fee =
  unsafePerformIO $ do
    configScript <- loadMarketConfigV2SuperLazy
    marketScript <- loadConfigurableMarketV2SuperLazy
    pure $ makeConfigurableMarketV2Helper' operatorAddr fee configScript marketScript

createV2SaleDatum :: AddressInEra ConwayEra -> Integer -> HashableScriptData
createV2SaleDatum sellerAddr costOfAsset =
  -- Convert  to Plutus.Address
  let plutusAddr =  addrInEraToPlutusAddress sellerAddr
      datum = SimpleSale plutusAddr costOfAsset
   in unsafeHashableScriptData $  fromPlutusData $ toData datum
