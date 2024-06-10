{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NumericUnderscores #-}

module Cardano.Marketplace.Common.TransactionUtils where


import Cardano.Kuber.Data.Parsers
  ( parseAssetId,

    parseAssetNQuantity,
    parseScriptData,
    parseValueText, scriptDataParser, parseSignKey
  )
import Cardano.Kuber.Util
    ( pkhToMaybeAddr, skeyToAddrInEra, queryUtxos, toPlutusAddress )
import qualified Data.Text as T
import qualified Data.ByteString.Char8 as BS8

import Plutus.Contracts.V2.SimpleMarketplace (SimpleSale (SimpleSale), simpleMarketplacePlutusV2)


import Control.Exception (throwIO)
import Data.Maybe (fromMaybe)
import qualified Data.Set as Set
import qualified Data.Map as Map
import Data.List (intercalate)
import Cardano.Kuber.Console.ConsoleWritable (showStr)
import qualified Data.Text.Lazy as TLE
import qualified Data.Aeson.Text as Aeson
import qualified Data.Text.IO as T
import System.Environment (getEnv)
import qualified Data.Aeson as A
import qualified Data.Aeson.Text as A
import Cardano.Api
import Cardano.Api.Shelley (Address(..))
import qualified PlutusLedgerApi.V2 as Plutus
import Cardano.Kuber.Util (fromPlutusData, fromPlutusAddress)
import Cardano.Kuber.Api
import GHC.Base (Alternative((<|>)))



marketAddressShelley :: NetworkId -> Address ShelleyAddr
marketAddressShelley network = makeShelleyAddress network scriptCredential NoStakeAddress

marketAddressInEra :: NetworkId -> AddressInEra ConwayEra
marketAddressInEra network = makeShelleyAddressInEra ShelleyBasedEraConway network scriptCredential NoStakeAddress

scriptCredential :: PaymentCredential
scriptCredential = PaymentCredentialByScript marketHash
  where
    marketHash = hashScript marketScript
    marketScript = PlutusScript PlutusScriptV2 simpleMarketplacePlutusV2



createSaleDatum :: AddressInEra ConwayEra -> Integer -> HashableScriptData
createSaleDatum sellerAddr costOfAsset =
  -- Convert AddressInEra to Plutus.Address
  let plutusAddr =  toPlutusAddress sellerAddrShelley
      sellerAddrShelley = case sellerAddr of {
         AddressInEra atie ad -> case ad of
          addr@(ShelleyAddress net cre sr )-> addr  
          _  -> error "Byron era address Not supported"

          }
      datum = SimpleSale plutusAddr costOfAsset

   in unsafeHashableScriptData $  fromPlutusData $ Plutus.toData datum

getTxIdFromTx :: Tx ConwayEra -> String
getTxIdFromTx tx = T.unpack $ serialiseToRawBytesHexText $ getTxId $ getTxBody tx


getSignKey :: [Char] -> IO (SigningKey PaymentKey)
getSignKey skeyfile =
  getPath >>=  T.readFile  >>= parseSignKey
  where
  getPath = if not (null skeyfile) && head skeyfile == '~'
                          then (do
                            home <- getEnv "HOME"
                            pure  $ home ++  drop 1 skeyfile
                            )
                          else pure skeyfile

runBuildAndSubmit :: (HasKuberAPI api, HasSubmitApi api) => TxBuilder -> Kontract api w FrameworkError (Tx ConwayEra)
runBuildAndSubmit   txBuilder =  do 
        tx<- kBuildTx txBuilder
        kSubmitTx (InAnyCardanoEra ConwayEra tx) 
        liftIO $ putStrLn $ "Tx Submitted :" ++  (getTxIdFromTx tx)
        pure tx