{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeApplications #-}

module Cardano.Marketplace.V2.Core where

import Cardano.Api
import Cardano.Api.Shelley (ProtocolParameters, ReferenceScript (ReferenceScriptNone), fromPlutusData, scriptDataToJsonDetailedSchema, toPlutusData)
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

import qualified Debug.Trace as Debug
import Data.Functor ((<&>))
import Control.Exception (throw)


mint ::  VerificationKey PaymentKey -> AssetName -> Integer -> TxBuilder
mint vKey assetName amount = 
  let script = RequireSignature $ verificationKeyHash vKey
  in txMintSimpleScript @(SimpleScript ) script [(assetName, Quantity amount)]


createReferenceScript ::  AddressInEra ConwayEra -> TxBuilder
createReferenceScript  receiverAddr = do
    txPayToWithReferenceScript  receiverAddr mempty ( TxScriptPlutus $ toTxPlutusScript $   simpleMarketplacePlutusV2)


-- sellToken :: String -> Integer -> SigningKey PaymentKey -> Maybe (AddressInEra  BabbageEra ) -> Address ShelleyAddr -> IO ()
-- sellToken  itemStr cost sKey mSellerAddr marketAddr = do
--   let addrShelley = skeyToAddr sKey (getNetworkId ctx)
--       sellerAddr =case mSellerAddr of
--         Nothing -> skeyToAddrInEra  sKey (getNetworkId ctx)
--         Just ad -> ad 
--   item <- parseAssetNQuantity $ T.pack itemStr
--   let saleDatum = constructDatum sellerAddr cost
--       marketAddrInEra =  marketAddressInEra (getNetworkId ctx)
--       txOperations =
--         txPayToScriptWithData marketAddrInEra (valueFromList [item]) saleDatum
--           <> txWalletSignKey sKey
--   putStrLn $  "InlineDatum : " ++ encodeScriptData saleDatum
--   submitTransaction ctx txOperations 

-- data UtxoWithData = UtxoWithData
--   {
--    uwdTxIn :: TxIn,
--    uwdTxOut :: TxOut CtxUTxO BabbageEra,
--    uwdScriptData :: ScriptData,
--    uwdSimpleSale :: SimpleSale,
--    uwdSellerAddr :: AddressInEra BabbageEra
--   }

-- buyToken ::  Text -> Maybe String -> SigningKey PaymentKey -> Address ShelleyAddr -> Kontract api w FrameworkError ()
-- buyToken ctx txInText datumStrM sKey marketAddr = do
--   dcInfo <- withDetails ctx
--   UtxoWithData txIn txOut scriptData sSale@(SimpleSale _ priceOfAsset) sellerAddrInEra <- getUtxoWithData ctx txInText datumStrM marketAddr
--   let sellerPayOperation = txPayTo sellerAddrInEra (ensureMinAda sellerAddrInEra (lovelaceToValue $ Lovelace priceOfAsset) (dciProtocolParams dcInfo))
--   redeemMarketUtxo dcInfo txIn txOut sKey sellerPayOperation scriptData SMP.Buy

-- withdrawToken ::  Text -> Maybe String -> SigningKey PaymentKey -> Address ShelleyAddr -> Kontract api w FrameworkError ()
-- withdrawToken ctx txInText datumStrM sKey marketAddr = do
--   dcInfo <- withDetails ctx
--   UtxoWithData txIn txOut scriptData _ sellerAddrInEra <- getUtxoWithData ctx txInText datumStrM marketAddr
--   let sellerSignOperation = txSignBy sellerAddrInEra
--   redeemMarketUtxo dcInfo txIn txOut sKey sellerSignOperation scriptData SMP.Withdraw

-- getUtxoWithData ::  Text -> Maybe String -> Address ShelleyAddr -> IO UtxoWithData
-- getUtxoWithData ctx txInText datumStrM marketAddr= do
--   txIn <- parseTxIn txInText
--   UTxO uMap <- queryMarketUtxos ctx marketAddr
--   let txOut = unMaybe "Error couldn't find the given txin in market utxos." $ Map.lookup txIn uMap
--   (scriptData, simpleSale) <- getSimpleSaleTuple datumStrM txOut
--   let nwId = getNetworkId ctx
--       sellerAddrInEra = plutusAddressToAddressInEra nwId (sellerAddress simpleSale)
--   pure $ UtxoWithData txIn txOut scriptData simpleSale sellerAddrInEra

-- getSimpleSaleTuple :: Maybe String -> TxOut CtxUTxO BabbageEra -> IO (ScriptData, SimpleSale)
-- getSimpleSaleTuple datumStrM txOut = case datumStrM of
--     Nothing -> do
--       let inlineDatum = findInlineDatumFromTxOut txOut
--           simpleSale = unMaybe "Failed to convert datum to SimpleSale" $ Plutus.fromBuiltinData $ dataToBuiltinData $ toPlutusData inlineDatum
--       pure $ Debug.trace  (show simpleSale) (inlineDatum, simpleSale)
--     Just datumStr -> do
--       simpleSaleTuple@(scriptData, _) <- parseSimpleSale datumStr
--       let datumHashMatches = matchesDatumhash (hashScriptData scriptData) txOut
--       if not datumHashMatches
--         then error "Error : The given txin doesn't match the datumhash of the datum."
--         else pure $ Debug.trace (show simpleSaleTuple) simpleSaleTuple

-- redeemMarketUtxo ::  TxIn -> TxOut CtxUTxO BabbageEra -> 
--   SigningKey PaymentKey -> TxBuilder -> ScriptData -> SMP.MarketRedeemer -> Kontract api w FrameworkError ()
-- redeemMarketUtxo  txIn txOut sKey extraOperations scriptData redeemer = do
--   let walletAddr = getAddrEraFromSignKey dcInfo sKey
--       redeemUtxoOperation = txRedeemUtxo txIn txOut  simpleMarketplacePlutusV2   (fromPlutusData $ toData redeemer) Nothing
--       txOperations =
--         redeemUtxoOperation
--           <> txWalletAddress walletAddr
--           <> txWalletSignKey sKey
--           <> extraOperations
--   submitTransaction dcInfo txOperations 
--   putStrLn "Done"



-- findInlineDatumFromTxOut :: TxOut CtxUTxO BabbageEra -> ScriptData
-- findInlineDatumFromTxOut (TxOut _ _ (TxOutDatumInline _ sd) _) = Debug.trace (show sd) sd
-- findInlineDatumFromTxOut _ = error "Error : The given txin doesn't have an inline datum. Please provide a datum using --datum '<datum string>'."



-- throwLeft e = case e of
--   Left e -> throw e
--   Right v ->  pure  v


-- txSimpleSaleScript = PlutusScript PlutusScriptV2 simpleMarketplacePlutusV2