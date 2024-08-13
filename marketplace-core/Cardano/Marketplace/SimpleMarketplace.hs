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
  , sell :: AddressInEra BabbageEra -> Value -> Integer -> AddressInEra BabbageEra -> Kontract api w FrameworkError (TxBuilder_ BabbageEra)
  , buy :: TxIn -> Kontract api w FrameworkError (TxBuilder_ BabbageEra)
  , buyWithRefScript :: TxIn -> TxIn -> Kontract api w FrameworkError (TxBuilder_ BabbageEra)
  , withdraw :: TxIn -> Kontract api w FrameworkError (TxBuilder_ BabbageEra)
  , withdrawWithRefScript :: TxIn -> TxIn -> Kontract api w FrameworkError (TxBuilder_ BabbageEra)
}

assetInfo :: TxOut CtxUTxO BabbageEra -> (AddressInEra BabbageEra, Integer)
assetInfo assetUTxO = do 
  case getSimpleSaleInfo (Testnet (NetworkMagic 4)) assetUTxO of 
    Right sellerAndPrice -> sellerAndPrice
    Left str -> error (str)

placeOnSell' marketAddr saleItem datum = 
  txPayToScriptWithData_ marketAddr saleItem datum

buyFromMarket' spendTxIn buyUtxo script buyRedeemer = 
  txRedeemUtxo_ spendTxIn buyUtxo script buyRedeemer maybeExUnits
  <> txPayTo_   (sellerAddr) (valueFromList [ (AdaAssetId, Quantity price)])
  where 
    (sellerAddr, price) = assetInfo buyUtxo

withdrawFromMarket' withdrawTxIn withdrawUTxO script withdrawRedeemer = 
  txRedeemUtxo_ withdrawTxIn withdrawUTxO script withdrawRedeemer maybeExUnits
  <> txSignBy_ (sellerAddr)
  where 
    (sellerAddr, _) = assetInfo withdrawUTxO

buyFromMarketWithRefScript' spendTxIn refTxIn buyUtxo buyRedeemer =
  txRedeemUtxoWithReferenceScript_ refTxIn spendTxIn buyUtxo buyRedeemer  maybeExUnits
  <> txPayTo_ (sellerAddr) (valueFromList [ (AdaAssetId, Quantity price)])
  where 
    (sellerAddr, price) = assetInfo buyUtxo

withdrawFromMarketWithRefScript' withdrawTxIn refTxIn withdrawUTxO withdrawRedeemer = 
  txRedeemUtxoWithReferenceScript_ refTxIn withdrawTxIn withdrawUTxO withdrawRedeemer maybeExUnits 
  <> txSignBy_ (sellerAddr)  
  where 
    (sellerAddr, price) = assetInfo withdrawUTxO