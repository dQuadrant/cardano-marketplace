{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeApplications #-}

module Cardano.Marketplace.V3.Core where


import Cardano.Marketplace.SimpleMarketplace
import Cardano.Api
import Cardano.Api.Shelley
import Cardano.Kuber.Api
import Plutus.Contracts.V3.SimpleMarketplace (simpleMarketplacePlutusV3, simpleMarketplacePlutusV3Lazy, simpleMarketplacePlutusV3SuperLazy, SimpleSale (SimpleSale), MarketRedeemer (Withdraw, Buy))
import PlutusTx
import Cardano.Kuber.Util (toPlutusAddress, addrInEraToPlutusAddress)
import Cardano.Marketplace.ConfigurableMarketplace
import qualified Plutus.Contracts.V3.SimpleMarketplace as Marketplace
import qualified Plutus.Contracts.V3.ConfigurableMarketplace as V3ConfigurableMarketplace
import qualified Plutus.Contracts.V3.MarketplaceConfig as V3MarketConfig
import qualified PlutusLedgerApi.V3 as PlutusV3
import Cardano.Marketplace.Common.TransactionUtils (resolveTxIn)

simpleMarketV3Helper' :: (HasChainQueryAPI api) => PlutusScript PlutusScriptV3 -> SimpleMarketHelper api w
simpleMarketV3Helper' script = SimpleMarketHelper {
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

-- buyFromMarket :: IsPlutusScript sc => TxIn -> sc -> TxBuilder
buyFromMarket spendTxIn script = do
  (tin, tout) <- resolveTxIn spendTxIn
  pure $ buyFromMarket' tin tout script buyRedeemer

withdrawFromMarket withdrawTxIn script = do
  (tin, tout) <- resolveTxIn withdrawTxIn
  kWrapParser $ Right $ withdrawFromMarket' tin tout script withdrawRedeemer

placeOnSell marketAddr saleItem cost sellerAddress = do 
  kWrapParser $ Right $ placeOnSell' marketAddr saleItem (createV3SaleDatum sellerAddress cost)

buyFromMarketWithRefScript spendTxIn refTxIn = do 
  (tin, tout) <- resolveTxIn spendTxIn
  kWrapParser $ Right $ buyFromMarketWithRefScript' tin refTxIn tout buyRedeemer

withdrawFromMarketWithRefScript withdrawTxIn refTxIn = do
  (tin, tout) <- resolveTxIn withdrawTxIn
  kWrapParser $ Right $ withdrawFromMarketWithRefScript' tin refTxIn tout withdrawRedeemer 

simpleMarketV3Helper :: SimpleMarketHelper ChainConnectInfo w 
simpleMarketV3Helper = simpleMarketV3Helper' simpleMarketplacePlutusV3

simpleMarketV3HelperLazy :: SimpleMarketHelper ChainConnectInfo w 
simpleMarketV3HelperLazy = simpleMarketV3Helper' simpleMarketplacePlutusV3Lazy

simpleMarketV3HelperSuperLazy :: SimpleMarketHelper ChainConnectInfo w 
simpleMarketV3HelperSuperLazy = simpleMarketV3Helper' simpleMarketplacePlutusV3SuperLazy

makeConfigurableMarketV3Helper' :: 
  AddressInEra era -> 
  Integer -> 
  Script PlutusScriptV3 -> 
  (V3ConfigurableMarketplace.MarketConstructor -> PlutusScript PlutusScriptV3) -> 
  ConfigurableMarketHelper
makeConfigurableMarketV3Helper' operatorAddr fee marketConfigScript configurableMarketScript= 
  let operatorAddress = addrInEraToPlutusAddress operatorAddr
      ownerAddress = operatorAddress
      marketConfig = V3MarketConfig.MarketConfig operatorAddress operatorAddress fee
      marketConstructor = V3ConfigurableMarketplace.MarketConstructor  ( 
        PlutusV3.ScriptHash $ PlutusV3.toBuiltin $ serialiseToRawBytes $ hashTxScript  $ TxScriptPlutus mConfigScript)
      mConfigScript = toTxPlutusScript marketConfigScript
    in
    ConfigurableMarketHelper {
        cmMarketScript = toTxPlutusScript $ configurableMarketScript marketConstructor 
      , cmConfigScript = mConfigScript
      , cmMakeSaleDatum = createV3SaleDatum
      , cmWithdrawRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData V3ConfigurableMarketplace.Withdraw
      , cmBuyRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData V3ConfigurableMarketplace.Buy
      , cmConfigDatum = unsafeHashableScriptData $ fromPlutusData$ toData marketConfig
      }

makeConfigurableMarketV3Helper :: AddressInEra era -> Integer -> ConfigurableMarketHelper
makeConfigurableMarketV3Helper operatorAddr fee = 
  makeConfigurableMarketV3Helper' operatorAddr fee 
  V3MarketConfig.marketConfigPlutusScript 
  V3ConfigurableMarketplace.configurableMarketPlutusScript

makeConfigurableMarketV3HelperLazy :: AddressInEra era -> Integer -> ConfigurableMarketHelper
makeConfigurableMarketV3HelperLazy operatorAddr fee = 
  makeConfigurableMarketV3Helper' operatorAddr fee 
  V3MarketConfig.marketConfigPlutusScriptLazy 
  V3ConfigurableMarketplace.configurableMarketPlutusScriptLazy

makeConfigurableMarketV3HelperSuperLazy :: AddressInEra era -> Integer -> ConfigurableMarketHelper
makeConfigurableMarketV3HelperSuperLazy operatorAddr fee = 
  makeConfigurableMarketV3Helper' operatorAddr fee 
  V3MarketConfig.marketConfigPlutusScriptSuperLazy 
  V3ConfigurableMarketplace.configurableMarketPlutusScriptSuperLazy  

createV3SaleDatum :: AddressInEra BabbageEra -> Integer -> HashableScriptData
createV3SaleDatum sellerAddr costOfAsset =
  -- Convert AddressInEra to Plutus.Address
  let plutusAddr =  toPlutusAddress sellerAddrShelley
      sellerAddrShelley = case sellerAddr of {
         AddressInEra atie ad -> case ad of
          addr@(ShelleyAddress net cre sr )-> addr  
          _  -> error "Byron era address Not supported"

          }
      datum = SimpleSale plutusAddr costOfAsset
   in unsafeHashableScriptData $  fromPlutusData $ toData datum