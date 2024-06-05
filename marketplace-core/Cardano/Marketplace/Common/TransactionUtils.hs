{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NumericUnderscores #-}

module Cardano.Marketplace.Common.TransactionUtils where


import Cardano.Kuber.Api
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




marketAddressShelley :: NetworkId -> Address ShelleyAddr
marketAddressShelley network = makeShelleyAddress network scriptCredential NoStakeAddress

marketAddressInEra :: NetworkId -> AddressInEra BabbageEra
marketAddressInEra network = makeShelleyAddressInEra ShelleyBasedEraBabbage network scriptCredential NoStakeAddress

scriptCredential :: PaymentCredential
scriptCredential = PaymentCredentialByScript marketHash
  where
    marketHash = hashScript marketScript
    marketScript = PlutusScript PlutusScriptV2 simpleMarketplacePlutusV2

queryMarketUtxos :: HasChainQueryAPI a =>  Address ShelleyAddr -> Kontract a s FrameworkError (UTxO BabbageEra)
queryMarketUtxos  addr = 
  kQueryUtxoByAddress  $ Set.singleton  (toAddressAny addr)


constructDatum :: AddressInEra BabbageEra -> Integer -> ScriptData
constructDatum sellerAddr costOfAsset =
  -- Convert AddressInEra to Plutus.Address
  let plutusAddr =  toPlutusAddress sellerAddrShelley
      sellerAddrShelley = case sellerAddr of { AddressInEra atie ad -> case ad of
                                                 addr@(ShelleyAddress net cre sr )-> addr  
                                                 _  -> error "Byron era address Not supported"

                                                 }
      datum = SimpleSale plutusAddr costOfAsset

   in fromPlutusData $ Plutus.toData datum

getTxIdFromTx :: Tx BabbageEra -> String
getTxIdFromTx tx = T.unpack $ serialiseToRawBytesHexText $ getTxId $ getTxBody tx

unMaybe :: String -> Maybe a -> a
unMaybe errStr m = case m of
  Nothing -> error errStr
  Just x -> x


printTxBuilder :: TxBuilder -> IO ()
printTxBuilder txBuilder = do
  putStrLn $ BS8.unpack $ prettyPrintJSON txBuilder




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
