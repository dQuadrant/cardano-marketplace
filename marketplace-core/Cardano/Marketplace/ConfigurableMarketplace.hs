{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE DeriveGeneric #-}

module Cardano.Marketplace.ConfigurableMarketplace where

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
import GHC.Generics (Generic)


data ConfigurableMarketHelper = ConfigurableMarketHelper {
    cmMarketScript :: !TxPlutusScript
  , cmConfigScript :: !TxPlutusScript
  , cmMakeSaleDatum :: AddressInEra ConwayEra -> Integer -> HashableScriptData
  , cmWithdrawRedeemer :: HashableScriptData
  , cmBuyRedeemer :: HashableScriptData
  , cmConfigDatum :: HashableScriptData
}deriving (Generic)

instance Show ConfigurableMarketHelper where
    show (ConfigurableMarketHelper marketScript configScript _ withdrawRedeemer buyRedeemer configDatum) =
        "ConfigurableMarketHelper {\n" ++
        "  cmMarketScript = " ++ show (hashTxScript$  TxScriptPlutus marketScript) ++ ",\n" ++
        "  cmConfigScript = " ++ show (hashTxScript$  TxScriptPlutus configScript) ++ ",\n" ++
        "  cmMakeSaleDatum = <function>,\n" ++
        "  cmWithdrawRedeemer = " ++ show withdrawRedeemer ++ ",\n" ++
        "  cmBuyRedeemer = " ++ show buyRedeemer ++ ",\n" ++
        "  cmConfigDatum = " ++ show configDatum ++ "\n" ++
        "}"

sellBuilder :: ConfigurableMarketHelper -> AddressInEra ConwayEra ->  Value -> Integer -> AddressInEra  ConwayEra  -> TxBuilder
sellBuilder smHelper marketAddr saleItem cost  sellerAddr 
  = txPayToScriptWithData marketAddr saleItem (cmMakeSaleDatum smHelper sellerAddr cost)

buyTokenBuilder ::  HasChainQueryAPI api => 
  ConfigurableMarketHelper ->
  Maybe TxIn -> 
  TxIn -> 
  Maybe (AddressInEra ConwayEra, Integer, TxIn) -> 
  Kontract api w FrameworkError TxBuilder
buyTokenBuilder mHelper refTxIn txin  feeInfo = do
  netid<- kGetNetworkId
  (tin, tout) <- resolveTxIn txin
  kWrapParser $ buyTokenBuilder' (cmMarketScript mHelper ) (cmBuyRedeemer mHelper )  netid refTxIn txin tout feeInfo

withdrawTokenBuilder ::  HasChainQueryAPI api => ConfigurableMarketHelper -> Maybe TxIn -> TxIn  -> Kontract api w FrameworkError TxBuilder
withdrawTokenBuilder mHelper refTxIn txin  = do
  netid<- kGetNetworkId
  (tin, tout) <- resolveTxIn txin
  kWrapParser $ withdrawTokenBuilder' (cmMarketScript mHelper ) (cmWithdrawRedeemer mHelper) netid refTxIn txin tout