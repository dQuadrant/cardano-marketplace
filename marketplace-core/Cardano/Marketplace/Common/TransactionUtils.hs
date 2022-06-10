{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}

module Cardano.Marketplace.Common.TransactionUtils where

import Cardano.Api
import Cardano.Api.Byron (Address (ByronAddress))
import Cardano.Api.Shelley
  ( Address (ShelleyAddress),
    AsType (AsAlonzoEra),
    Lovelace (Lovelace),
    ProtocolParameters,
    Quantity (Quantity),
    fromPlutusData,
    fromShelleyStakeReference,
    shelleyPayAddrToPlutusPubKHash,
    toShelleyStakeAddr,
    toShelleyStakeCredential, toPlutusData
  )
import qualified Cardano.Api.Shelley as Shelley
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers
  ( parseAssetIdText,
    parseAssetNQuantity,
    parseScriptData,
    parseValueText, scriptDataParser
  )
import Cardano.Kuber.Util
import qualified Cardano.Ledger.Address as Shelley
import Cardano.Ledger.Alonzo.Tx (TxBody (txfee))
import qualified Cardano.Ledger.BaseTypes as Shelley (Network (..))
import Cardano.Marketplace.Common.ConsoleWritable
import Cardano.Marketplace.Common.TextUtils
import Codec.Serialise (serialise)
import Control.Concurrent (MVar, newMVar, putMVar, readMVar, takeMVar, threadDelay, withMVar)
import Control.Exception
  ( SomeException (SomeException),
    throwIO,
    try,
  )
import Control.Monad (foldM, forM, forM_, void)
import Control.Monad.Reader (MonadIO (liftIO), ReaderT (runReaderT))
import qualified Data.Aeson as Aeson
import qualified Data.ByteString.Char8 as BS8
import Data.Char (toLower)
import Data.Data (Data, Typeable)
import Data.Functor ((<&>))
import Data.List (intercalate, isSuffixOf, sort)
import Data.Map (keys)
import qualified Data.Map as Map
import Data.Maybe (fromMaybe, mapMaybe)
import qualified Data.Set as Set
import Data.Text (Text, strip)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import qualified Data.Text.IO as TIO
import GHC.Conc (atomically, newTVar)
import GHC.IO.Handle.FD (stdout)
import GHC.Int (Int64)
import Plutus.Contracts.V1.SimpleMarketplace (SimpleSale (..), simpleMarketplacePlutus)
import qualified Plutus.V1.Ledger.Address as Plutus
import Plutus.V1.Ledger.Api (ToData (toBuiltinData), toData)
import qualified Plutus.V1.Ledger.Api as Plutus
import Plutus.V1.Ledger.Value (AssetClass (AssetClass))
import System.Console.CmdArgs
import System.Directory (doesFileExist, getCurrentDirectory, getDirectoryContents)
import qualified Data.Text.Lazy.Encoding as TL
import qualified Data.Text.Lazy as TL

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

marketAddressInEra :: NetworkId -> AddressInEra AlonzoEra
marketAddressInEra network = makeShelleyAddressInEra network scriptCredential NoStakeAddress

scriptCredential :: PaymentCredential
scriptCredential = PaymentCredentialByScript marketHash
  where
    marketHash = hashScript marketScript
    marketScript = PlutusScript PlutusScriptV1 simpleMarketplacePlutus

queryMarketUtxos :: ChainInfo v => v -> Address ShelleyAddr -> IO (UTxO AlonzoEra)
queryMarketUtxos ctx addr = do
  utxos <- queryUtxos (getConnectInfo ctx) $ Set.singleton (toAddressAny addr)
  case utxos of
    Left err -> error $ "Error while querying utxos " ++ show err
    Right utxos' -> pure utxos'

constructDatum :: Shelley.Address ShelleyAddr -> Integer -> ScriptData
constructDatum sellerAddr costOfAsset =
  -- Convert AddressInEra to Plutus.Address
  let plutusPkh = unMaybe "Error seller address must not be script address" $ shelleyPayAddrToPlutusPubKHash sellerAddr
      plutusAddr = Plutus.Address (Plutus.PubKeyCredential plutusPkh) Nothing
      datum =
        SimpleSale
          { sellerAddress = plutusAddr,
            priceOfAsset = costOfAsset
          }
   in fromPlutusData $ toData datum

getTxIdFromTx :: Tx AlonzoEra -> String
getTxIdFromTx tx = T.unpack $ serialiseToRawBytesHexText $ getTxId $ getTxBody tx

calculateMinimumLovelace :: ShelleyBasedEra AlonzoEra -> AddressInEra AlonzoEra -> Value -> ProtocolParameters -> Lovelace
calculateMinimumLovelace era addr value pParams = do
  let txOut = TxOut addr (TxOutValue MultiAssetInAlonzoEra value) TxOutDatumNone
      minValueE = calculateMinimumUTxO era txOut pParams
  case minValueE of
    Left err -> error $ "Error while calculating minimum value " ++ show err
    Right minValue -> selectLovelace minValue

unMaybe :: String -> Maybe a -> a
unMaybe errStr m = case m of
  Nothing -> error errStr
  Just x -> x

simpleMintingScript :: SimpleScript SimpleScriptV2
simpleMintingScript =
  RequireAllOf
    [ RequireSignature "edea1516f727e4dd650833f37b80109d55b64529244595612aacf62c"
    ]

plutusAddressToAddressInEra :: NetworkId -> Plutus.Address -> AddressInEra AlonzoEra
plutusAddressToAddressInEra nw addr = unMaybe "Error Cannot convert pluuts address to address in era" $ pkhToMaybeAddr nw $ unMaybe "Error Validator hash is not supported." $ Plutus.toPubKeyHash addr

printTxBuilder :: TxBuilder -> IO ()
printTxBuilder txBuilder = do
  putStrLn $ BS8.unpack $ prettyPrintJSON txBuilder

parseSimpleSale :: String -> IO (ScriptData, SimpleSale)
parseSimpleSale datumStr = do
  let datumObj = unMaybe "Error : Invalid datum json string." $ Aeson.decode $ TL.encodeUtf8 $ TL.pack datumStr
  scriptData <- scriptDataParser datumObj
  let simpleSale@SimpleSale {sellerAddress, priceOfAsset} = unMaybe "Failed to convert datum to SimpleSale" $ Plutus.fromData $ toPlutusData scriptData
  return (scriptData, simpleSale)

submitTransaction :: ChainInfo v => v -> TxBuilder -> SigningKey PaymentKey -> IO ()
submitTransaction dcInfo txOperations sKey = do
  txBodyE <- txBuilderToTxBodyIO dcInfo txOperations
  txBody <- case txBodyE of
    Left fe -> throwIO fe
    Right txBody -> pure txBody
  tx <- signAndSubmitTxBody (getConnectInfo dcInfo) txBody [sKey]
  putStrLn $ "Transaction submitted sucessfully with transaction hash " ++ getTxIdFromTx tx
