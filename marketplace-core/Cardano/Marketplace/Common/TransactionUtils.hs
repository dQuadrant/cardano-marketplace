{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}

module Cardano.Marketplace.Common.TransactionUtils where

import Cardano.Api
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers
  ( parseAssetIdText,
    parseAssetNQuantity,
    parseScriptData,
    parseValueText, scriptDataParser
  )
import Cardano.Kuber.Util
    ( pkhToMaybeAddr, skeyToAddrInEra, queryUtxos )
import qualified Data.Text as T
import qualified Data.ByteString.Char8 as BS8
import qualified Plutus.V1.Ledger.Address as Plutus
import qualified Plutus.V1.Ledger.Api as Plutus
import Plutus.Contracts.V1.SimpleMarketplace (SimpleSale (SimpleSale), simpleMarketplacePlutus)
import Cardano.Api.Shelley

import qualified Cardano.Api.Shelley as Shelley
import Plutus.V1.Ledger.Api (toData)
import Control.Exception (throwIO)
import Data.Maybe (fromMaybe)
import qualified Data.Set as Set
import Plutus.Contracts.V1.MarketplaceOffer



--Convert to Addr any from Addr in era
getAddrAnyFromEra addrEra = fromMaybe (error "unexpected error converting address to another type") (deserialiseAddress AsAddressAny (serialiseAddress addrEra))

--Get Addr any from given sign key
getAddrAnyFromSignKey ctx signKey =
  getAddrAnyFromEra $ skeyToAddrInEra signKey (getNetworkId ctx)

--Get Addr in era from  given sign key
getAddrEraFromSignKey ctx signKey =
  skeyToAddrInEra signKey (getNetworkId ctx)

marketAddressShelley :: NetworkId -> Address ShelleyAddr
marketAddressShelley network = makeShelleyAddress network scriptCredential NoStakeAddress

offerAddressShelley :: NetworkId -> Address ShelleyAddr 
offerAddressShelley network = makeShelleyAddress network scriptCredential NoStakeAddress
    where
      scriptCredential :: Cardano.Api.Shelley.PaymentCredential
      scriptCredential = PaymentCredentialByScript offerHash
      
      offerHash = hashScript offerScript
      offerScript = PlutusScript PlutusScriptV1 offerScriptPlutus

offerAddressInEra net = makeShelleyAddressInEra net scriptCredential NoStakeAddress
    where
      scriptCredential :: Cardano.Api.Shelley.PaymentCredential
      scriptCredential = PaymentCredentialByScript offerHash
      
      offerHash = hashScript offerScript
      offerScript = PlutusScript PlutusScriptV1 offerScriptPlutus
marketAddressInEra :: NetworkId -> AddressInEra AlonzoEra
marketAddressInEra network = makeShelleyAddressInEra network scriptCredential NoStakeAddress

scriptCredential :: Cardano.Api.Shelley.PaymentCredential
scriptCredential = PaymentCredentialByScript marketHash
  where
    marketHash = hashScript marketScript
    marketScript = PlutusScript PlutusScriptV1 simpleMarketplacePlutus

queryMarketUtxos :: ChainInfo v => v -> Address ShelleyAddr -> IO (UTxO AlonzoEra)
queryMarketUtxos ctx addr = do
  utxos <- queryUtxos (getConnectInfo ctx) $ Set.singleton  (toAddressAny addr)
  case utxos of
    Left err -> error $ "Error while querying utxos " ++ show err
    Right utxos' -> pure utxos'

constructDatum :: Shelley.Address ShelleyAddr -> Integer -> ScriptData
constructDatum sellerAddr costOfAsset =

  -- Convert AddressInEra to Plutus.Address
  let plutusPkh = unMaybe "Error seller address must not be script address" $ shelleyPayAddrToPlutusPubKHash sellerAddr
      plutusAddr = Plutus.Address (Plutus.PubKeyCredential plutusPkh) Nothing
      datum = SimpleSale plutusAddr costOfAsset

   in fromPlutusData $ toData datum

getTxIdFromTx :: Tx AlonzoEra -> String
getTxIdFromTx tx = T.unpack $ serialiseToRawBytesHexText $ getTxId $ getTxBody tx

unMaybe :: String -> Maybe a -> a
unMaybe errStr m = case m of
  Nothing -> error errStr
  Just x -> x

plutusAddressToAddressInEra :: NetworkId -> Plutus.Address -> AddressInEra AlonzoEra
plutusAddressToAddressInEra nw addr = unMaybe "Error Cannot convert pluuts address to address in era" $ pkhToMaybeAddr nw $ unMaybe "Error Validator hash is not supported." $ Plutus.toPubKeyHash addr

printTxBuilder :: TxBuilder -> IO ()
printTxBuilder txBuilder = do
  putStrLn $ BS8.unpack $ prettyPrintJSON txBuilder

parseSimpleSale :: String -> IO (ScriptData, SimpleSale)
parseSimpleSale datumStr = do
  scriptData <- parseScriptData $ T.pack datumStr
  let simpleSale = unMaybe "Failed to convert datum to SimpleSale" $ Plutus.fromData $ toPlutusData scriptData
  return (scriptData, simpleSale)

submitTransaction :: ChainInfo v => v -> TxBuilder -> SigningKey PaymentKey -> IO ()
submitTransaction dcInfo txOperations sKey = do
  txBodyE <- txBuilderToTxBodyIO dcInfo txOperations
  txBody <- case txBodyE of
    Left fe -> throwIO fe
    Right txBody -> pure txBody
  tx <- signAndSubmitTxBody (getConnectInfo dcInfo) txBody [sKey]
  putStrLn $ "Transaction submitted sucessfully with transaction hash " ++ getTxIdFromTx tx
