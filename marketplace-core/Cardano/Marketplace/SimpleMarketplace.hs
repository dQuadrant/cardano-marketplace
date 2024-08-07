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

data SimpleMarketHelper api w = SimpleMarketHelper {
    simpleMarketScript :: TxPlutusScript
  , sell :: AddressInEra ConwayEra -> Value -> Integer -> AddressInEra ConwayEra -> Kontract api w FrameworkError TxBuilder
  , buy :: TxIn -> Kontract api w FrameworkError TxBuilder
  , buyWithRefScript :: TxIn -> TxIn -> Kontract api w FrameworkError TxBuilder
  , withdraw :: TxIn -> Kontract api w FrameworkError TxBuilder
  , withdrawWithRefScript :: TxIn -> TxIn -> Kontract api w FrameworkError TxBuilder
}

assetInfo :: TxOut CtxUTxO ConwayEra -> (AddressInEra ConwayEra, Integer)
assetInfo assetUTxO = do 
  case getSimpleSaleInfo (Testnet (NetworkMagic 4)) assetUTxO of 
    Right sellerAndPrice -> sellerAndPrice
    Left str -> error (str)

placeOnSell' marketAddr saleItem datum = 
  txPayToScriptWithData marketAddr saleItem datum

buyFromMarket' spendTxIn buyUtxo script buyRedeemer = 
  txRedeemUtxo spendTxIn buyUtxo script buyRedeemer  Nothing
  <> txPayTo   (sellerAddr) (valueFromList [ (AdaAssetId, Quantity price)])
  where 
    (sellerAddr, price) = assetInfo buyUtxo

withdrawFromMarket' withdrawTxIn withdrawUTxO script withdrawRedeemer = 
  txRedeemUtxo withdrawTxIn withdrawUTxO script withdrawRedeemer  Nothing
  <> txSignBy (sellerAddr)
  where 
    (sellerAddr, _) = assetInfo withdrawUTxO

buyFromMarketWithRefScript' spendTxIn refTxIn buyUtxo buyRedeemer =
  txRedeemUtxoWithReferenceScript refTxIn spendTxIn buyUtxo buyRedeemer  Nothing
  <> txPayTo (sellerAddr) (valueFromList [ (AdaAssetId, Quantity price)])
  where 
    (sellerAddr, price) = assetInfo buyUtxo

withdrawFromMarketWithRefScript' withdrawTxIn refTxIn withdrawUTxO withdrawRedeemer = 
  txRedeemUtxoWithReferenceScript refTxIn withdrawTxIn withdrawUTxO withdrawRedeemer Nothing 
  <> txSignBy (sellerAddr)  
  where 
    (sellerAddr, price) = assetInfo withdrawUTxO