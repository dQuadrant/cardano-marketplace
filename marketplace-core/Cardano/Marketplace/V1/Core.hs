{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}

module Cardano.Marketplace.V1.Core where

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
    scriptDataToJsonDetailedSchema,
    shelleyPayAddrToPlutusPubKHash,
    toShelleyStakeAddr,
    toShelleyStakeCredential,
  )
import qualified Cardano.Api.Shelley as Shelley
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers
  ( parseAssetIdText,
    parseAssetNQuantity,
    parseScriptData,
    parseTxIn,
    parseValueText,
  )
import Cardano.Kuber.Util
import qualified Cardano.Ledger.Address as Shelley
import Cardano.Ledger.Alonzo.Tx (TxBody (txfee))
import qualified Cardano.Ledger.BaseTypes as Shelley (Network (..))
import Cardano.Marketplace.Common.ConsoleWritable
import Cardano.Marketplace.Common.TextUtils
import Cardano.Marketplace.Common.TransactionUtils
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
import Data.ByteString.Lazy.Char8 (toStrict)
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
import qualified Plutus.Contracts.V1.SimpleMarketplace as SMP
import qualified Plutus.V1.Ledger.Address as Plutus
import Plutus.V1.Ledger.Api (ToData (toBuiltinData), toData)
import qualified Plutus.V1.Ledger.Api as Plutus
import Plutus.V1.Ledger.Value (AssetClass (AssetClass))

simpleMintTest ctx signKey = do
  let addrEra = getAddrEraFromSignKey ctx signKey
      mintScript = SimpleScript SimpleScriptV2 simpleMintingScript
      policyId = scriptPolicyId mintScript
  mint ctx signKey addrEra policyId "testtoken" 100_000_000_000_000
-- mint ctx signKey addrEra policyId "testtoken" 1

mint ctx signKey addrEra policyId assetName amount = do
  let txBuilder =
        txWalletAddress addrEra
          <> txMint
            [ TxMintData
                policyId
                (SimpleScriptWitness SimpleScriptV2InAlonzo SimpleScriptV2 simpleMintingScript)
                (valueFromList [(AssetId policyId assetName, Quantity amount)])
            ]
  txBodyE <- txBuilderToTxBodyIO ctx txBuilder
  case txBodyE of
    Left fe -> error $ "Error: " ++ show fe
    Right txBody -> do
      tx <- signAndSubmitTxBody (getConnectInfo ctx) txBody [signKey]
      let txId = getTxId txBody
      putStrLn "Transaction for mint submitted sucessfully."

sellToken :: ChainInfo v => v -> String -> Integer -> SigningKey PaymentKey -> Address ShelleyAddr -> IO ()
sellToken ctx itemStr cost sKey marketAddr = do
  let addrShelley = skeyToAddr sKey (getNetworkId ctx)
      sellerAddrInEra = getAddrEraFromSignKey ctx sKey
  item <- parseAssetNQuantity $ T.pack itemStr
  let lockedValue = valueFromList [item, (AdaAssetId, 2_000_000)]
      saleDatum = constructDatum addrShelley cost
      txOperations =
        txPayToScript (marketAddressInEra $ getNetworkId ctx) lockedValue (hashScriptData saleDatum)
          <> txWalletAddress sellerAddrInEra
  submitTransaction ctx txOperations sKey
  putStrLn "\nDatum to be used for buying :"
  putStrLn (BS8.unpack $ toStrict $ Aeson.encode $ scriptDataToJsonDetailedSchema saleDatum)
  putStrLn $ "\nMarket Address : " ++ T.unpack (serialiseAddress marketAddr)

buyToken :: ChainInfo v => v -> Text -> String -> SigningKey PaymentKey -> Address ShelleyAddr -> IO ()
buyToken ctx txInText datumStr sKey marketAddr = do
  dcInfo <- withDetails ctx
  (scriptData, simpleSale@SimpleSale {sellerAddress, priceOfAsset}) <- parseSimpleSale datumStr
  txIn <- parseTxIn txInText
  UTxO uMap <- queryMarketUtxos ctx marketAddr
  let txOut = unMaybe "Error couldn't find the given txin in market utxos." $ Map.lookup txIn uMap
  if not $ matchesDatumhash (hashScriptData scriptData) txOut
    then error "Error : The given txin doesn't match the datumhash of the datum."
    else do
      let nwId = getNetworkId ctx
          buyerAddr = getAddrEraFromSignKey ctx sKey
          sellerAddrInEra = plutusAddressToAddressInEra nwId sellerAddress
          sellerPayOperation = txPayTo sellerAddrInEra (ensureMinAda sellerAddrInEra (lovelaceToValue $ Lovelace priceOfAsset) (dciProtocolParams dcInfo))
          redeemUtxoOperation = txRedeemUtxo txIn txOut marketScriptToScriptInAnyLang scriptData (fromPlutusData $ Plutus.toData SMP.Buy)
          txOperations =
            sellerPayOperation
              <> redeemUtxoOperation
              <> txWalletAddress buyerAddr
      submitTransaction dcInfo txOperations sKey
      putStrLn "Done"
  where
    matchesDatumhash datumHash (TxOut _ (TxOutValue _ value) (TxOutDatumHash _ hash)) = hash == datumHash
    matchesDatumhash _ _ = False

    marketScriptToScriptInAnyLang = ScriptInAnyLang (PlutusScriptLanguage PlutusScriptV1) (PlutusScript PlutusScriptV1 simpleMarketplacePlutus)

    ensureMinAda :: AddressInEra AlonzoEra -> Value -> ProtocolParameters -> Value
    ensureMinAda addr value pParams =
      if diff > 0
        then value <> lovelaceToValue diff
        else value
      where
        diff = minLovelace - currentLovelace
        minLovelace = calculateMinimumLovelace ShelleyBasedEraAlonzo addr value pParams
        currentLovelace = selectLovelace value

withdrawToken :: ChainInfo v => v -> Text -> String -> SigningKey PaymentKey -> Address ShelleyAddr -> IO ()
withdrawToken ctx txInText datumStr sKey marketAddr = do
  dcInfo <- withDetails ctx
  (scriptData, simpleSale@SimpleSale {sellerAddress, priceOfAsset}) <- parseSimpleSale datumStr
  txIn <- parseTxIn txInText
  UTxO uMap <- queryMarketUtxos ctx marketAddr
  let txOut = unMaybe "Error couldn't find the given txin in market utxos." $ Map.lookup txIn uMap
  if not $ matchesDatumhash (hashScriptData scriptData) txOut
    then error "Error : The given txin doesn't match the datumhash of the datum."
    else do
      let nwId = getNetworkId ctx
          buyerAddr = getAddrEraFromSignKey ctx sKey
          sellerAddrInEra = plutusAddressToAddressInEra nwId sellerAddress
          redeemUtxoOperation = txRedeemUtxo txIn txOut marketScriptToScriptInAnyLang scriptData (fromPlutusData $ Plutus.toData SMP.Withdraw)
          txOperations =
            redeemUtxoOperation
              <> txWalletAddress buyerAddr
      submitTransaction dcInfo txOperations sKey
      putStrLn "Done"
  where
    matchesDatumhash datumHash (TxOut _ (TxOutValue _ value) (TxOutDatumHash _ hash)) = hash == datumHash
    matchesDatumhash _ _ = False

    marketScriptToScriptInAnyLang = ScriptInAnyLang (PlutusScriptLanguage PlutusScriptV1) (PlutusScript PlutusScriptV1 simpleMarketplacePlutus)
