{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

module Cardano.Marketplace.Common.TransactionUtils where


import Cardano.Kuber.Data.Parsers
  ( parseAssetId,

    parseAssetNQuantity,
    parseScriptData,
    parseValueText, scriptDataParser, parseSignKey
  )
import Cardano.Kuber.Util
import qualified Data.Text as T
import qualified Data.ByteString.Char8 as BS8

import qualified Plutus.Contracts.V2.SimpleMarketplace as V2 
import qualified Plutus.Contracts.V3.SimpleMarketplace as V3

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
import Cardano.Api.Shelley (Address(..), toPlutusData)
import qualified PlutusLedgerApi.V2 as PlutusV2
import qualified PlutusLedgerApi.V3 as PlutusV3
import Cardano.Kuber.Util (fromPlutusData, fromPlutusAddress)
import Cardano.Kuber.Api 
import qualified Debug.Trace as Debug

maybeExUnits :: Maybe ExecutionUnits
maybeExUnits =  (Just $ ExecutionUnits {executionSteps=976270061, executionMemory=5718298})

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

withdrawTokenBuilder' :: IsPlutusScript script => script -> HashableScriptData ->  NetworkId -> Maybe TxIn ->   TxIn -> TxOut CtxUTxO ConwayEra -> Either String  TxBuilder
withdrawTokenBuilder' script redeemer netId refTxIn txIn tout = do 
    (sellerAddr , price) <- getSimpleSaleInfo netId tout
    case refTxIn of 
      Nothing -> pure $ txRedeemUtxo txIn tout script redeemer  Nothing
        <> txSignBy (sellerAddr)
      Just referenceScriptTxIn -> pure $ txRedeemUtxoWithReferenceScript referenceScriptTxIn txIn tout redeemer Nothing
        <> txSignBy (sellerAddr)  

getSimpleSaleInfo :: NetworkId -> TxOut CtxUTxO ConwayEra -> Either String (AddressInEra ConwayEra, Integer)
getSimpleSaleInfo netId (TxOut addr val datum refscript) = do
    (seller, price) <- case datum of
        TxOutDatumInline _ sd -> case PlutusV2.fromBuiltinData $ PlutusV2.dataToBuiltinData $ toPlutusData $ getScriptData sd of
            Just (V2.SimpleSale seller price) -> Right (seller, price)
            Nothing -> case PlutusV3.fromBuiltinData $ PlutusV3.dataToBuiltinData $ toPlutusData $ getScriptData sd of
                Just (V3.SimpleSale seller price) -> Right (seller, price)
                Nothing -> Left "Unable to parse datum as V2 or V3 SimpleSale"
        _ -> Left "Unexpected datum type"
    
    sellerAddr <- case fromPlutusAddress netId seller of
        Just addr -> Right addr
        Nothing -> Left "Invalid address present in datum of the Utxo to be bought"
    
    Right (AddressInEra (ShelleyAddressInEra ShelleyBasedEraConway) sellerAddr, price)

createReferenceScript ::  IsPlutusScript script => script->AddressInEra ConwayEra -> TxBuilder
createReferenceScript script receiverAddr = do
    txPayToWithReferenceScript  receiverAddr mempty ( TxScriptPlutus $ toTxPlutusScript $ script)

buyTokenBuilder' :: IsPlutusScript script => script -> HashableScriptData -> NetworkId -> Maybe TxIn -> TxIn -> TxOut CtxUTxO ConwayEra -> Maybe (AddressInEra ConwayEra, Integer, TxIn) -> Either String  TxBuilder
buyTokenBuilder' script buyRedeemer netId refTxIn txIn tout feeInfo = do 
    (sellerAddr , price) <- getSimpleSaleInfo netId tout 
    let marketFeeOutput = case feeInfo of 
          Just (operator, fee, txin) -> txPayTo operator (valueFromList[(AdaAssetId, Quantity fee)])
              <> txReferenceTxIn txin
          Nothing -> mempty
    case refTxIn of 
          Nothing -> pure $ txRedeemUtxo txIn tout script buyRedeemer  Nothing
            <> txPayTo   (sellerAddr) (valueFromList [ (AdaAssetId, Quantity price)])
            <> marketFeeOutput
          Just referenceTxIn -> pure $ txRedeemUtxoWithReferenceScript referenceTxIn txIn tout buyRedeemer  Nothing
            <> txPayTo   (sellerAddr) (valueFromList [ (AdaAssetId, Quantity price)])
            <> marketFeeOutput
            
resolveTxIn:: HasChainQueryAPI api => TxIn -> Kontract api w FrameworkError (TxIn, TxOut CtxUTxO ConwayEra)
resolveTxIn txin = do 
  (UTxO uMap) :: UTxO ConwayEra <- kQueryUtxoByTxin  $ Set.singleton txin
  case Map.toList uMap  of 
    [] -> kError NodeQueryError $ "Provided Utxo not found " ++  T.unpack (renderTxIn txin )
    [(_,tout)]-> pure (txin,tout)

mintNativeAsset ::  VerificationKey PaymentKey -> AssetName -> Integer -> (AssetId, TxBuilder)
mintNativeAsset vKey assetName amount = 
  let script = RequireSignature $ verificationKeyHash vKey
      scriptHash = hashScript $ SimpleScript  script
      assetId = AssetId  (PolicyId scriptHash ) assetName 
  in (assetId, txMintSimpleScript  script [(assetName, Quantity amount)])

runBuildAndSubmit :: (HasKuberAPI api, HasSubmitApi api) => TxBuilder -> Kontract api w FrameworkError (Tx ConwayEra)
runBuildAndSubmit txBuilder =  do 
        tx<- kBuildTx txBuilder     
        kSubmitTx (InAnyCardanoEra ConwayEra tx) 
        liftIO $ putStrLn $ "Tx Submitted :" ++  (getTxIdFromTx tx)
        pure tx