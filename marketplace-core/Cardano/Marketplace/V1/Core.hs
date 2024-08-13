{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeApplications #-}

module Cardano.Marketplace.V1.Core where

import Cardano.Api
import Cardano.Api.Shelley (ProtocolParameters, ReferenceScript (ReferenceScriptNone), fromPlutusData, scriptDataToJsonDetailedSchema, toPlutusData, Address (ShelleyAddress))
import qualified Cardano.Api.Shelley as Shelley
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers
import Cardano.Kuber.Util
import Cardano.Marketplace.Common.TextUtils ()
import Cardano.Marketplace.Common.TransactionUtils
import Codec.Serialise (serialise)
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.Text as Aeson
import qualified Data.Map as Map
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Lazy as TLE
import Plutus.Contracts.V1.SimpleMarketplace hiding (Withdraw)
import qualified Debug.Trace as Debug
import Data.Functor ((<&>))
import Control.Exception (throw)
import qualified Data.Set as Set
import qualified Plutus.Contracts.V1.SimpleMarketplace as Marketplace
import PlutusLedgerApi.V1 (toData, dataToBuiltinData, FromData (fromBuiltinData))
import Cardano.Marketplace.SimpleMarketplace
import qualified PlutusLedgerApi.V1 as PlutusV1
import Cardano.Marketplace.ConfigurableMarketplace
import qualified Data.ByteString.Lazy as LBS
import qualified Data.ByteString.Char8 as BS8
import GHC.IO (unsafePerformIO)
import GHC.Conc (newTVarIO, atomically)
import GHC.Conc.Sync (readTVar, writeTVar)
import Data.Maybe (fromJust)

simpleMarketV1Helper' :: (HasChainQueryAPI api) => PlutusScript PlutusScriptV1 -> IO (SimpleMarketHelper api w)
simpleMarketV1Helper' script = do
  datumVar <- newTVarIO Nothing
  let sellf marketAddress saleItem cost sellerAddress = do 
        liftIO $ atomically $ do 
          writeTVar datumVar (Just $ (snd $ createV1SaleDatum (sellerAddress, cost)))
        placeOnSell marketAddress saleItem cost sellerAddress

      buyf assetTxIn = do 
        datum <- liftIO $ atomically $ do 
          readTVar datumVar
        buyFromMarket assetTxIn script datum

      buyWithRefScriptf assetTxIn referenceTxIn = do 
        datum <- liftIO $ atomically $ do 
          readTVar datumVar
        buyFromMarketWithRefScript assetTxIn referenceTxIn datum

      withdrawf withdrawTxIn = do 
        datum <- liftIO $ atomically $ do 
          readTVar datumVar
        withdrawFromMarket withdrawTxIn script datum

      withdrawWithRefScriptf withdrawTxIn refTxIn = do 
        datum <- liftIO $ atomically $ do 
          readTVar datumVar
        withdrawFromMarketWithRefScript withdrawTxIn refTxIn datum


  pure $ SimpleMarketHelper {
      simpleMarketScript = toTxPlutusScript script
    , sell = sellf
    , buy = buyf
    , buyWithRefScript = buyWithRefScriptf
    , withdraw = withdrawf
    , withdrawWithRefScript = withdrawWithRefScriptf
  }

buyRedeemer :: HashableScriptData
buyRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData Marketplace.Buy

withdrawRedeemer :: HashableScriptData
withdrawRedeemer = unsafeHashableScriptData $ fromPlutusData$ toData Marketplace.Withdraw

parseAssetInfo :: HashableScriptData -> (AddressInEra BabbageEra, Integer)
parseAssetInfo sd = 
  case PlutusV1.fromBuiltinData $ PlutusV1.dataToBuiltinData $ toPlutusData $ getScriptData sd of
            Just (Marketplace.SimpleSale seller price) ->  
              (
                  AddressInEra (ShelleyAddressInEra ShelleyBasedEraBabbage) 
                  (fromJust $ fromPlutusAddress (Testnet (NetworkMagic 4)) seller)
                
                , price
              )

buyFromMarket spendTxIn script datum = do 
  (tin, tout)<- resolveTxIn spendTxIn
  kWrapParser $ Right $ txRedeemUtxoWithDatum_ tin tout script (fromJust datum) buyRedeemer  maybeExUnits
    <> txPayTo_ (sellerAddr) (valueFromList [ (AdaAssetId, Quantity price)]) 
  where 
    (sellerAddr, price) = parseAssetInfo (fromJust datum)

withdrawFromMarket withdrawTxIn script datum = do
  (tin, tout) <- resolveTxIn (withdrawTxIn)
  kWrapParser $ Right $ txRedeemUtxoWithDatum_ tin tout script (v1SaleDatumInline datum) withdrawRedeemer  maybeExUnits
    <> txSignBy_ (sellerAddr)
  where 
    (sellerAddr, _) = parseAssetInfo (fromJust datum)

placeOnSell marketAddr saleItem cost sellerAddress = 
  kWrapParser $ Right $ txPayToScript_ marketAddr saleItem (v1SaleDatumHash (sellerAddress, cost))

buyFromMarketWithRefScript spendTxIn refTxIn datum = do
  (tin, tout) <- resolveTxIn spendTxIn
  kWrapParser $ Right $ txRedeemUtxoWithDatumAndReferenceScript_ refTxIn tin tout (v1SaleDatumInline datum) buyRedeemer  maybeExUnits
      <> txPayTo_ (sellerAddr) (valueFromList [ (AdaAssetId, Quantity price)])
  where 
    (sellerAddr, price) = parseAssetInfo (fromJust datum)

withdrawFromMarketWithRefScript withdrawTxIn refTxIn datum = do 
  (tin, tout) <- resolveTxIn withdrawTxIn
  kWrapParser $ Right $ txRedeemUtxoWithDatumAndReferenceScript_ refTxIn tin tout (v1SaleDatumInline datum) withdrawRedeemer maybeExUnits 
    <> txSignBy_ (sellerAddr)  
  where 
    (sellerAddr, price) = parseAssetInfo (fromJust datum)

simpleMarketV1Helper :: SimpleMarketHelper ChainConnectInfo w
simpleMarketV1Helper = unsafePerformIO $ simpleMarketV1Helper' simpleMarketplacePlutusV1

simpleMarketV1HelperSuperLazy :: SimpleMarketHelper ChainConnectInfo w
simpleMarketV1HelperSuperLazy = unsafePerformIO $ simpleMarketV1Helper' simpleMarketplacePlutusV1SuperLazy

v1SaleDatumInline datum = (snd $ createV1SaleDatum (parseAssetInfo (fromJust datum)))

v1SaleDatumHash sellerAndCost = (fst $ createV1SaleDatum sellerAndCost)

createV1SaleDatum :: (AddressInEra BabbageEra, Integer) -> (Hash ScriptData, HashableScriptData)
createV1SaleDatum (sellerAddr, costOfAsset) =
  unsafePerformIO $ do
    let plutusAddr = addrInEraToPlutusAddress sellerAddr
        datum = SimpleSale plutusAddr costOfAsset
        inline = unsafeHashableScriptData $ fromPlutusData $ toData datum
        hash = hashScriptDataBytes inline
    return (hash, inline)