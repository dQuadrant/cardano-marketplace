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
import Plutus.Contracts.V3.SimpleMarketplace (simpleMarketplacePlutusV3, SimpleSale (SimpleSale), MarketRedeemer (Withdraw, Buy))
import PlutusTx
import Cardano.Kuber.Util (toPlutusAddress, addrInEraToPlutusAddress)
import Cardano.Marketplace.ConfigurableMarketplace
import qualified Plutus.Contracts.V3.ConfigurableMarketplace as V3ConfigurableMarketplace
import qualified Plutus.Contracts.V3.MarketplaceConfig as V3MarketConfig
import qualified PlutusLedgerApi.V3 as PlutusV3

simpleMarketV3Helper :: SimpleMarketHelper
simpleMarketV3Helper = SimpleMarketHelper {
    simpleMarketScript = toTxPlutusScript simpleMarketplacePlutusV3
  , makeSaleDatum = createV3SaleDatum
  , withdrawRedeemer  = unsafeHashableScriptData $ fromPlutusData$ toData Withdraw
  , buyRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData Buy
}

makeConfigurableMarketV3Helper operatorAddr fee = 
  let operatorAddress = addrInEraToPlutusAddress operatorAddr
      ownerAddress = operatorAddress
      marketConfig = V3MarketConfig.MarketConfig operatorAddress operatorAddress fee
      marketConstructor = V3ConfigurableMarketplace.MarketConstructor  ( 
        PlutusV3.ScriptHash $ PlutusV3.toBuiltin $ serialiseToRawBytes $ hashTxScript  $ TxScriptPlutus mConfigScript)
      mConfigScript = toTxPlutusScript $ V3MarketConfig.marketConfigPlutusScript
    in
    ConfigurableMarketHelper {
        cmMarketScript = toTxPlutusScript $ V3ConfigurableMarketplace.configurableMarketPlutusScript marketConstructor 
      , cmConfigScript = mConfigScript
      , cmMakeSaleDatum = createV3SaleDatum
      , cmWithdrawRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData V3ConfigurableMarketplace.Withdraw
      , cmBuyRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData V3ConfigurableMarketplace.Buy
      , cmConfigDatum = unsafeHashableScriptData $ fromPlutusData$ toData marketConfig
      }


createV3SaleDatum :: AddressInEra ConwayEra -> Integer -> HashableScriptData
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