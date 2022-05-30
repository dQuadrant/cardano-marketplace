{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Use newtype instead of data" #-}
{-# HLINT ignore "Use ++" #-}
{-# LANGUAGE NamedFieldPuns #-}

module Cardano.Marketplace.V1.RequestModels where


import Cardano.Api

import Servant (JSON)
import Cardano.Binary (fromCBOR, decodeFull, ToCBOR (toCBOR))
import Servant.API.Generic (Generic)
import Data.Aeson.Types
    ( FromJSON(parseJSON),
      ToJSON(toJSON),
      Parser,
      Value(String, Number, Object),
      (.!=),
      (.:),
      (.:?),
      fromJSON,
      object,
      Result(Success, Error),
      KeyValue((.=)), Pair )
import Control.Monad (mzero)
import qualified Data.Text as T
import Cardano.Api.Byron (FromJSON)
import qualified Data.HashMap.Strict as H
import Prelude hiding(String)
import qualified Prelude
import Data.Text.Conversions
import Data.Functor ((<&>))
import Cardano.Ledger.Mary.Value (PolicyID(policyID))
import Data.Text.Encoding as T
import Cardano.Kuber.Util hiding (toHexString)
import Cardano.Kuber.Api
import System.Console.CmdArgs (Typeable)
import Cardano.Kuber.Api
import Cardano.Api.Shelley
import Text.Read (readMaybe)
import qualified Data.Text.Encoding as TSE
import Data.Maybe (isNothing, fromMaybe)
import Data.Text (Text)
import qualified Data.Map as Map
import   Data.ByteString (ByteString)
import qualified Data.ByteString.Lazy as LBS
import Data.ByteString.Lazy (fromStrict, toStrict )
import Data.String (fromString, String)
import Data.Set(Set)
import qualified Cardano.Ledger.Serialization as Codec.CBOR.Read
import qualified Cardano.Binary as CBOR
import qualified Data.Set as Set
import Data.Map (Map)
import Codec.Serialise (serialise)
import Cardano.Ledger.Alonzo.Data (Data)
import Codec.CBOR.Write (toLazyByteString)
import Data.Aeson (encode, Value (Null, Array), decode, eitherDecode)
import Plutus.V1.Ledger.Api (toData, Address, PubKeyHash, Script)
import Cardano.Ledger.Alonzo.TxBody (TxBody(txfee))
import qualified Data.ByteString as BS
import Plutus.Contracts.V1.Auction (Auction)
import qualified Data.Text.Lazy.Encoding as TLE
import qualified Data.Text as Data.Text.Lazy
import qualified Data.Text as Data.Text.Internal.Lazy
import Cardano.Ledger.BaseTypes (Network)
import qualified Data.ByteString.Char8 as BSC
import qualified Data.HashMap.Strict as M
import qualified Data.List as List
import Cardano.Kuber.Data.Parsers (parseScriptData, parseSignKey, parseAssetId)
import Cardano.Marketplace.Common.TextUtils



newtype AssetModal= AssetModal AssetId deriving Show


newtype CostModal=CostModal (AssetId,Quantity)  deriving Show
newtype AddressModal= AddressModal (AddressInEra AlonzoEra) deriving Show
newtype SignKeyModal= SignKeyModal (SigningKey PaymentKey) deriving Show
newtype UtxoIdModal =UtxoIdModal (TxId,TxIx) deriving Show
newtype ShareModal = ShareModal (AddressInEra AlonzoEra,Integer) deriving Show
newtype WitnessModal = WitnessModal (KeyWitness AlonzoEra) deriving Show
newtype TxModal     = TxModal (Tx AlonzoEra) deriving Show



unAssetModal (AssetModal a) = a
unAddressModal (AddressModal a)=a
unSignKeyModal (SignKeyModal s) =s
unTxModal (TxModal t) = t
unWitnessModal (WitnessModal w)=w
unUtxoIdModal (UtxoIdModal x)  = x

unCostModal (CostModal c) =c

unMSignKeyModal :: Functor f => f SignKeyModal -> f (SigningKey PaymentKey)
unMSignKeyModal v =v <&> unSignKeyModal

parserForMaybe f  v= do
      case v of
        Just x -> do
          v <- f x
          pure $ Just v
        Nothing -> pure Nothing

data BuyReqModel=BuyReqModel{
    buyReqContext :: TxContextAddressesReq,
    byReqSellerDepositSkey ::Maybe (SigningKey PaymentKey),
    buyReqUtxo :: Maybe UtxoIdModal,
    buyReqAsset:: Maybe AssetId,
    buyReqDatum:: ScriptData,
    buyCollateral:: Maybe  UtxoIdModal -- use specific address as collateral, if not present, a suitable collateral will be choosen.
}

instance FromJSON BuyReqModel  where
  parseJSON  = \case
    Object o-> do
                BuyReqModel
                  <$> addressContextParser o
                  <*> (o .:? "sellerDepositSkey" <&> fmap unSignKeyModal)
                  <*> o .:? "utxoId"
                  <*> (o .:? "asset" <&> fmap unAssetModal)
                  <*> o `scriptDataParser`  "datum"
                  <*> (o.:? "collateral"  >>= parserForMaybe parseCollateral)
    _        -> fail "Expecting SaleRequest Object"

data WithdrawReqModel=WithdrawReqModel{
  withdrawDatum:: ScriptData,
  withdrawUtxo :: Maybe UtxoIdModal, -- this is the utxo we want to withdraw, if not present, one of the utxos matching the datahash will be chosen.
  withdrawAsset:: Maybe AssetModal, -- we are withdrawing this asset. if present, make sure that this asset is available in the utxo.
  withdrawAddress:: Maybe (AddressInEra AlonzoEra), -- If present, this is the seller address that wants to withdraw, otherwise it's computed from sellerAddress in the datum.
  withdrawCollateral:: Maybe  UtxoIdModal -- use specific address as collateral, if not present, a suitable collateral will be choosen.
}

instance FromJSON WithdrawReqModel where
  parseJSON  (Object o) =do
        WithdrawReqModel
          <$> o `scriptDataParser` "datum"
          <*> o .:? "utxoId"
          <*> (o.:? "asset")
          <*> (o .:? "receiverAddress" <&> fmap unAddressModal)
          <*> (o.:? "collateral" >>= parserForMaybe parseCollateral)
  parseJSON _ = fail "Expected Withdraw Req Object"


data OperatorWithdrawModel=OperatorWithdrawModel{
  opWithdrawDatum:: ScriptData,
  opWithdrawUtxo :: Maybe UtxoIdModal, -- this is the utxo we want to withdraw, if not present, one of the utxos matching the datahash will be chosen.
  opWithdrawAsset:: Maybe AssetModal, -- we are withdrawing this asset. if present, make sure that this asset is available in the utxo.
  opWithdrawWalletSignKey:: SigningKey PaymentKey,
  opWithdrawAddress:: Maybe (AddressInEra AlonzoEra) -- If present, this is the seller address that wants to withdraw, otherwise it's computed from skey.
}


instance FromJSON OperatorWithdrawModel where
  parseJSON  (Object o) =do
        OperatorWithdrawModel
          <$> o `scriptDataParser` "datum"
          <*> o .:? "utxoId"
          <*> (o.:? "asset")
          <*> (o .: "skey" <&>  unSignKeyModal )
          <*> (o .:? "receiverAddress" <&> fmap unAddressModal)
  parseJSON _ = fail "Expected Withdraw Req Object"


data SellReqModel = SellReqModel {
    sreqAsset :: CostModal,
    sreqParties:: [ShareModal],
    sreqCost:: CostModal,
    isSecondary:: Bool

} deriving ( Typeable)

instance FromJSON SellReqModel  where
  parseJSON  = \case
    Object o-> do
                SellReqModel
                  <$> o .: "asset"
                  <*> (o .:? "parties" .!= [])
                  <*> o .:  "cost"
                  <*> (o .:? "isSecondary" .!= False)
              where
                unAddress (Just (AddressModal addr))= Just addr
                unAddress _ = Nothing
    _        -> fail "Expecting SaleRequest Object"

data SellReqBundle = SellReqBundle {
  sReqContext :: TxContextAddressesReq,
  sReqSales :: [SellReqModel],
  sReqTopLevel :: Bool
}

instance FromJSON SellReqBundle where
  parseJSON v@(Object o) = do
      sales <- o .:? "sales"
      context <- addressContextParser o
      case sales of
        Nothing -> do
          sale <- parseJSON v
          pure $ SellReqBundle context [sale] True
        Just v ->  pure $ SellReqBundle  context v False
  parseJSON  _  = fail "Expecting SaleRequest Object"




data SaleCreateResponse = SaleCreateResponse {
  saleCreatetxRaw :: Tx AlonzoEra,
  saleResponses :: [ScriptData ],
  saleCreateTopLevel :: Bool -- return auctionResponse object in the top level
} deriving(Generic,Show )


saleRestoJSON txId index datum =  object [
      "utxoId" .= BSC.unpack (BS.concat [ serialiseToRawBytesHex  txId, BSC.pack ("#" ++ show index)]),
      "dataHash" .= datumHashHexString datum
      ]
  where
    datumHashHexString  :: ScriptData -> Text
    datumHashHexString sd =  T.pack $  tail $ init $  show $  hashScriptData sd

instance ToJSON SaleCreateResponse where
  toJSON (SaleCreateResponse _tx datums topLevel) =
      if topLevel
        then Object (M.insert "utxoId" utxoId   txRes)
        else
           object [
            "txResponse" .= toJSON (TxResponse _tx datums ),
            "sales" .=  mapDatums
          ]
    where
      Object txRes = toJSON $ TxResponse _tx datums
      utxoId = String $ T.pack $ BSC.unpack (BS.concat [ serialiseToRawBytesHex  _txid, BSC.pack "#0"])
      _txid= getTxId (getTxBody _tx)
      mapDatums = zipWith (saleRestoJSON _txid) [0..] datums



data TxContextAddressesReq = TxContextAddressesReq{
    txContextAddressesReqSignKey :: Maybe (SigningKey PaymentKey),
    txContextAddressesReqSenderAddr :: Maybe(AddressInEra AlonzoEra),
    txContextAddressesReqPayerAddr :: Maybe(AddressInEra AlonzoEra),
    txContextAddressesReqChangeAddr :: Maybe(AddressInEra AlonzoEra),
    txContextAddressesReqReceiverAddr :: Maybe (AddressInEra AlonzoEra),
    txContextAddressesReqKnownAddresses :: Map PubKeyHash (AddressInEra AlonzoEra)
  }

instance Show TxContextAddressesReq where
  show (TxContextAddressesReq payerSkey sender payer change receiver knownAddr)=  "TxContextAddressesReq("
                                                                      ++ "skey=" ++show payerSkey
                                                                      ++  ", sender=" ++ showAddr sender
                                                                      ++ ", payer="++ showAddr payer
                                                                      ++ ", change="++ showAddr change
                                                                      ++ ", receiver=" ++ showAddr receiver
                                                                      ++ ", knownAddresses={"++ List.intercalate ", " (map (T.unpack . serialiseAddress) $ Map.elems knownAddr)++"})"
      where

        showAddr a =case a of
          Just a ->   T.unpack $ serialiseAddress a
          Nothing -> "null"

data TxContextAddresses = TxContextAddresses{
    txContextSenderAddr :: AddressInEra AlonzoEra,
    txContextPayerAddr :: AddressInEra AlonzoEra,
    txContextChangeAddr :: AddressInEra AlonzoEra,
    txContextReceiverAddr :: AddressInEra AlonzoEra,
    txContextKnownAddresses :: Map PubKeyHash (AddressInEra AlonzoEra)
  }
instance Show TxContextAddresses where
  show (TxContextAddresses sender payer change receiver knownAddr)=  "TxContextAddresses(sender=" ++ showAddr sender
                                                                      ++ ", payer="++ showAddr payer
                                                                      ++ ", change="++ showAddr change
                                                                      ++ ", receiver=" ++ showAddr receiver
                                                                      ++ ", knownAddresses={"++ List.intercalate ", " (map showAddr $ Map.elems knownAddr)++"})"
      where
        showAddr a =  T.unpack $ serialiseAddress a

addressContextParser o = do
      TxContextAddressesReq
      <$> (o.:? "skey" <&> fmap unSignKeyModal)
      <*> (o.:? "senderAddress" <&> fmap unAddressModal)
      <*> (o.:? "payerAddress" <&> fmap unAddressModal)
      <*> (o.:? "changeAddress" <&> fmap unAddressModal)
      <*> (o.:? "receiverAddress" <&> fmap unAddressModal)
      <*> ( Map.fromList . map (\x -> (toPkh x, x)) <$> (o.:? "knownAddresses" .!= [] <&> map unAddressModal))

    where
      toPkh x = case addrInEraToPkh x of
              Just pkh -> pkh
              Nothing -> error $ "Can't convert address" ++ T.unpack (serialiseAddress  x) ++ " to PubKeyHash"

resolveAddressByPkh :: TxContextAddressesReq -> NetworkId-> PubKeyHash -> AddressInEra AlonzoEra
resolveAddressByPkh addresses  network  pkh = case Map.lookup pkh (txContextAddressesReqKnownAddresses addresses) of
    Nothing -> case pkhToMaybeAddr network pkh of
      Nothing -> error $ "Can't convert Pkh" ++ show pkh ++ " to Shelly Address"
      Just aie -> aie
    Just aie -> aie

populateAddresses' addrContext network mPkh=do
  case populateAddresses addrContext network mPkh  of
    Left s -> fail s
    Right tca -> pure tca
 -- looks a bit complicated, but basically, populate addresses with default addresses for whatever is missing in the context.
populateAddresses :: TxContextAddressesReq -> NetworkId -> Maybe PubKeyHash-> Either String TxContextAddresses
populateAddresses  (TxContextAddressesReq mSkey mSender mPayer mChange mReceiver knownAddresses' ) network mDefaultUser =do
  payerAddr <-case mPayer of
    Nothing -> case mSkey of
      Nothing -> case mSender of
        Nothing -> case mDefaultUser of
          Nothing -> case mChange of
            Nothing -> case mReceiver of
              Nothing ->  Left "$.senderAddress $.paymentAddress $.receiverAddress $.skey"
              Just aie -> pure aie
            Just aie -> pure aie
          Just pkh -> case mChange of
            Nothing -> case mReceiver of
              Nothing ->  Left "$.senderAddress $.paymentAddress $.receiverAddress $.skey"
              Just aie -> pure aie
            Just aie -> pure aie
        Just aie -> pure aie
      Just sk -> lookupPkh $ sKeyToPkh  sk
    Just aie -> pure aie
  senderAddr <-case mSender of
    Nothing ->case mDefaultUser of
          Nothing ->  pure payerAddr
          Just pkh ->   lookupPkh pkh
    Just aie -> pure aie
  let receiverAddr = Data.Maybe.fromMaybe senderAddr mReceiver
      changeAddress = fromMaybe senderAddr mChange
  pure $ TxContextAddresses senderAddr payerAddr changeAddress receiverAddr knownAddresses
  where
    lookupPkh pkh =  case Map.lookup pkh knownAddresses of
            Nothing -> case pkhToMaybeAddr network pkh of
              Nothing -> Left  $ "Can't convert pkh: " ++ show pkh ++ " to address"
              Just aie -> pure aie
            Just aie -> pure aie
    matchPkhOrConvert pkh addr = case addrInEraToPkh  addr of
      Nothing ->  Left  $ "Can't convert pkh: " ++ show pkh ++ " to address"
      Just pkh' ->  if pkh == pkh'
                      then pure addr
                    else lookupPkh pkh

    extendAddr map mAddr=case mAddr of
      Just aie  -> case addrInEraToPkh  aie of
        Just pkh -> Map.insert pkh aie map
        Nothing -> map
      Nothing   -> map
    v0= extendAddr knownAddresses' mPayer
    v1= extendAddr v0 mReceiver
    v2 = extendAddr v1  mSender
    v3= extendAddr v2 mChange
    knownAddresses = case mDefaultUser of
      Nothing -> v3
      Just pkh -> case Map.lookup pkh v3 of
        Nothing -> case pkhToMaybeAddr network pkh  of
          Nothing -> v3
          Just addr -> Map.insert pkh addr v3
        Just aie -> v3

data StartAuctionModel = StartAuctionModel {
    astartAsset :: CostModal,
    astartParties:: [ShareModal],
    astartStartingBid:: CostModal,
    astartStartTime :: Maybe Integer,
    astartEndtime :: Maybe Integer,
    astartMinIncrement:: Integer
} deriving (Generic, Show,Typeable)

data  StartAuctionBundle = StartAuctionBundle {
  astartCotext :: TxContextAddressesReq,
  astartAuctions:: [StartAuctionModel],
  aTopLevel :: Bool
}

instance FromJSON StartAuctionBundle where
  parseJSON v@(Object o ) = do
                          auctions <- o .:? "auctions"
                          context <- addressContextParser o
                          case auctions of
                            Nothing -> do
                              auction <- parseJSON v
                              pure $ StartAuctionBundle context [auction] True
                            Just v ->  pure $ StartAuctionBundle  context v False
  parseJSON _ = fail "Expecting StartAuctionModal Object"



instance FromJSON StartAuctionModel where
  parseJSON (Object o) =
            StartAuctionModel
              <$> o .: "asset"
              <*> (o .:? "parties" .!= [])
              <*> o .:  "startingBid"
              <*> o.:? "startTime"
              <*> o.:? "endTime"
              <*> o.: "minimunBidIncrement"
        where
          unAddress (Just (AddressModal addr))= Just addr
          unAddress _ = Nothing
  parseJSON _ = fail "Expecting StartAuctionModal Object"

data BidReqModel = BidReqModel{
    bidReqAuction :: Auction,
    bidReqContext :: TxContextAddressesReq,
    bidReqUtxo :: Maybe UtxoIdModal,
    bidReqAsset:: Maybe AssetId,
    bidReqDatum:: ScriptData,
    bidReqCollateral:: Maybe  UtxoIdModal, -- use specific address as collateral, if not present, a suitable collateral will be choosen.
    bidReqAmount :: Maybe Integer,
    bidReqBidEverything :: Bool
  }deriving ( Show,Typeable)


instance FromJSON BidReqModel  where
  parseJSON  = \case
    Object o-> do
              BidReqModel
                  <$> (o.: "auctionConstructor">>= auctionParser )
                  <*> addressContextParser o
                  <*> o .:? "utxoId"
                  <*> (o .:? "asset" <&> fmap unAssetModal)
                  <*> o `scriptDataParser`  "datum"
                  <*> (o.:? "collateral"  >>= parserForMaybe parseCollateral)
                  <*> (o.:? "bidAmount")
                  <*> (o.:? "bidEverything" .!= False)
    _        -> fail "Expecting BidRequestModal Object"

data BidResponse = BidResponse {
  bidResTxResponse :: TxResponse
}
instance ToJSON BidResponse where
  toJSON (BidResponse b@TxResponse{txRaw}) = Object (M.insert "utxoId" (String $T.pack utxoId) txRes)
    where
      Object txRes=toJSON b
      utxoId=  BSC.unpack (BS.concat [ serialiseToRawBytesHex  (getTxId (getTxBody txRaw)), BSC.pack "#0"])


auctionParser  t =
  case eitherDecode  $ TLE.encodeUtf8  t of
    Left s -> fail s
    Right any -> pure  any

data FinalizeAuctionModel=FinalizeAuctionModel{
    finalizeReqAucttion :: Auction,
    finalizeReqContext :: TxContextAddressesReq,
    finalizeReqSellerDepositSkey ::Maybe (SigningKey PaymentKey),
    finalizeReqUtxo :: Maybe UtxoIdModal,
    finalizeReqAsset:: Maybe AssetId,
    finalizeReqDatum:: ScriptData,
    finalizeReqCollateral:: Maybe  UtxoIdModal -- use specific address as collateral, if not present, a suitable collateral will be choosen.
}
instance FromJSON FinalizeAuctionModel where
  parseJSON  = \case
    Object o-> do
      FinalizeAuctionModel
          <$> (o.: "auctionConstructor" >>= auctionParser )
          <*> addressContextParser o
          <*> (o .:? "sellerDepositSkey" <&> fmap unSignKeyModal)
          <*> o .:? "utxoId"
          <*> (o .:? "asset" <&> fmap unAssetModal)
          <*> o `scriptDataParser`  "datum"
          <*> (o.:? "collateral"  >>= parserForMaybe parseCollateral)
    _  -> fail "Expecting BidRequestModal Object"


data OperatorCancelAuctionModel = OperatorCancelAuctionModel {
  opCancelAuctionContext ::  TxContextAddressesReq,
  opCancelAuctionAuction :: Auction,
  opCanceAuctionModel :: ScriptData  ,
  opCancelAuctionUtxo :: Maybe UtxoIdModal, -- this is the utxo we want to withdraw, if not present, one of the utxos matching the datahash will be chosen.
  opCancelAuctionAsset:: Maybe AssetId -- we are withdrawing this asset. if present, make sure that this asset is available in the utxo.
}

instance FromJSON OperatorCancelAuctionModel where
  parseJSON  (Object o) =do
        OperatorCancelAuctionModel
          <$> addressContextParser o
          <*> (o.: "auctionConstructor" >>= auctionParser )
          <*> o `scriptDataParser`  "datum"
          <*> o .:? "utxoId"
          <*> (o .:? "asset" <&> fmap unAssetModal)
  parseJSON _ = fail "Expected Withdraw Req Object"


data CancelAuctionModel = CancelAuctionModel {
  cancelAuctionContext ::  TxContextAddressesReq,
  cancelAuctionAuction :: Auction,
  cancelAuctionScriptData :: ScriptData,
  cancelAuctionUtxo :: Maybe UtxoIdModal, -- this is the utxo we want to withdraw, if not present, one of the utxos matching the datahash will be chosen.
  cancelAuctionAsset:: Maybe AssetId -- we are withdrawing this asset. if present, make sure that this asset is available in the utxo.
}

instance FromJSON CancelAuctionModel where
  parseJSON  (Object o) =do
        CancelAuctionModel
          <$> addressContextParser o
          <*> (o.: "auctionConstructor" >>=auctionParser)
          <*> o `scriptDataParser` "datum"
          <*> o .:? "utxoId"
          <*> (o .:? "asset" <&> fmap unAssetModal)

  parseJSON _ = fail "Expected Withdraw Req Object"

data PaymentUtxoModel = PaymentUtxoModel {
  paymentValue :: Cardano.Api.Shelley.Value,
  receiverAddress:: AddressInEra AlonzoEra,
  deductFees :: Bool, -- pay this address paymentValue -txFee.
  addChange :: Bool
}
instance FromJSON PaymentUtxoModel where
  parseJSON (Object o) = PaymentUtxoModel
                          <$> (o .: "values" <&> map unCostModal <&> valueFromList )
                          <*> (o .: "receiverAddress" <&> unAddressModal)
                          <*> o .:? "deductFees" .!= False
                          <*> o .:? "addChange"  .!=False
  parseJSON _           =   fail "Expecting PaymentUtxo Object"


data PaymentReqModel = PaymentReqModel {
  preqSkey :: SigningKey PaymentKey,
  preqReceivers::[PaymentUtxoModel],
  preqPayerAddress:: Maybe (AddressInEra  AlonzoEra),
  preqChangeAddress:: Maybe (AddressInEra AlonzoEra),
  spendEverything :: Bool,
  ignoreTinySurplus :: Bool, -- if value < minUtxoLovelace remains as change, send it to the receiver.
  ignoreTinyInsufficient:: Bool -- if value < minUtxoLovelace is insufficient in the wallet, don't fail and pay receiver a bit less.
}

instance FromJSON PaymentReqModel  where
  parseJSON  = \case
    Object o-> PaymentReqModel
                <$> o `signKeyParser` "skey"
                <*> o .:? "receivers" .!=[]
                <*> (o.:? "payerAddress" <&> fmap unAddressModal)
                <*> (o.:? "changeAddress" <&> fmap unAddressModal)
                <*> o.:? "spendEverything" .!=False
                <*> o.:? "ignoreSurplus" .!=False
                <*> o .:? "ignoneInsufficient" .!= False
    _        -> fail "Expecting SaleRequest Object"

data MoveFundModel= MoveFundModel{
  moveFundSKey:: SigningKey PaymentKey,
  moveFundTo :: AddressModal
}

data SubmitTxModal=SubmitTxModal{
  rawTx:: Tx AlonzoEra,
  witness:: Maybe (KeyWitness AlonzoEra)
}

instance FromJSON SubmitTxModal where
  parseJSON (Object o) = do
    SubmitTxModal
    <$> (o .: "tx" <&> unTxModal)
    <*> (o .:? "witness" <&> fmap unWitnessModal)
  parseJSON _ = fail "Expected SubmitTx Object"


data AuctionResponse = AuctionResponse {
  auctionResScript :: Cardano.Api.Shelley.PlutusScript PlutusScriptV1,
  auctionResDatum :: ScriptData,
  auctionResAddress ::Cardano.Api.Shelley.Address ShelleyAddr ,
  auctionResParameter :: Auction
} deriving (Show)

data AuctionCreateResponse = AuctionCreateResponse {
  _txRaw :: Tx AlonzoEra,
  auctionResponses :: [AuctionResponse],
  topLevel :: Bool -- return auctionResponse object in the top level
} deriving(Generic,Show )



auctionResToJSON txId index (AuctionResponse script datum addr auction) =  object [
      "utxoId" .= BSC.unpack (BS.concat [ serialiseToRawBytesHex  txId, BSC.pack ("#" ++ show index)]),
      "address"    .=  serialiseAddress addr,
      "auctionConstructor" .= TLE.decodeUtf8 (encode  auction),
      "dataHash" .= datumHashHexString datum,
      "auctionScript" .=  ( toHexString ( serialiseToCBOR script):: String)
      ]
  where
    datumHashHexString  :: ScriptData -> Text
    datumHashHexString sd =  T.pack $  tail $ init $  show $  hashScriptData sd

instance ToJSON AuctionCreateResponse where
  toJSON (AuctionCreateResponse _tx auctions topLevel) =
      if topLevel
        then Object (M.insert "txResponse"  (toJSON $ TxResponse _tx [datum] ) auctionJson)
        else
           object [
            "txResponse" .= toJSON (TxResponse _tx (map auctionResDatum auctions) ),
            "auctions" .=  mapAuctions
          ]
    where
      Object auctionJson =auctionResToJSON _txid 0 $ head auctions
      _txid= getTxId (getTxBody _tx)
      AuctionResponse _ datum _ _ = head auctions
      mapAuctions = zipWith (auctionResToJSON _txid) [0..] auctions


data TxResponse=TxResponse{
  txRaw :: Tx AlonzoEra,
  datums :: [ ScriptData ]
} deriving (Generic,Show)

instance  ToJSON  TxResponse where
    toJSON (TxResponse tx datums ) =object [
            "tx"  .= txHex,
            "datums"   .=  object ( map datumPair datums),
            "txHash" .= getTxId ( getTxBody  tx),
            "fee"  .= case getTxBody tx of {
                        ShelleyTxBody sbe tb scs tbsd m_ad tsv -> txfee tb
                  }
        ]
      where
        txHex ::  Text
        txHex  = toHexString $ serialiseToCBOR tx

        datumPair  d =  datumHashHexString d .= datumHexString d

        datumHashHexString  :: ScriptData -> Text
        datumHashHexString sd =  T.pack $  tail $ init $  show $  hashScriptData sd

        datumHexString :: ScriptData -> Text
        datumHexString _data=
          T.decodeUtf8  $ toStrict $ encode $ scriptDataToJson ScriptDataJsonDetailedSchema   _data

        dataToBytes  :: Data AlonzoEra  -> LBS.ByteString
        dataToBytes d = toLazyByteString $  toCBOR d
        toLedger :: ScriptData  -> Data AlonzoEra
        toLedger=toAlonzoData

-- txResultToResponse (TxResult fee ins body txbody) txId= case ShelleyTxBody _  _  ([Script (ShelleyLedgerEra era)]) (TxBodyScriptData era) (Maybe (AuxiliaryData (ShelleyLedgerEra era))) (TxScriptValidity era) of
--   TxResponse txId ()
--   where
--     maptype:: (TxIn, BuildTxWith BuildTx (Witness WitCtxTxIn AlonzoEra)) ->ScriptDataHash
--     maptype (_, a)= case a of

data BalanceResponse = BalanceResponse{
  utxos :: UTxO AlonzoEra
} deriving (Generic, Show,ToJSON)

instance FromJSON AssetModal where
  parseJSON  v=  case v of
      Object o  -> do
        policy <- (o .: "policyId") ::Parser T.Text
        name   <- (o .: "name") :: Parser T.Text
        asset <-parseAssetId policy name
        pure $ AssetModal asset
      String s  -> if T.null s
                    then pure $ AssetModal AdaAssetId
                    else case T.split  (== '.') s of
                      [policyText,assetText] -> parseAssetId policyText assetText <&> AssetModal
                      _                      -> formatError
      _           -> formatError
      where
        formatError=fail "Asset id must be object {\"policyId\":\"PolicyHexStr\",\"tokenName\":\"tokenNameStr\"} or of format \"policyHex.assetName\""

instance ToJSON AssetModal where
   toJSON (AssetModal (AssetId policy name)) =object [ "policyId"  .= policy, "name"   .= name]
   toJSON (AssetModal AdaAssetId ) = object [ "policyId"  .= (""::T.Text), "name"   .= (""::T.Text)]



instance FromJSON CostModal where
  parseJSON (Object o ) = do
      policy <- o .: "policyId"
      name   <- o .: "name"
      asset  <- parseAssetId policy name
      value <- o .: "amount"
      pure $ CostModal (asset,Quantity value)
  parseJSON (Number n) = do
    let v = round n
    pure $ CostModal (AdaAssetId ,Quantity v)
  parseJSON _ = fail "Expected CostModal object"


instance FromJSON UtxoIdModal where
  parseJSON (Object o ) = do
    txid <- o.:"hash"
    index <- o.:"index"
    pure $ UtxoIdModal (txid,index)
  parseJSON (String v) =
    case T.split (== '#') v of
      [txHash, index] ->
        case deserialiseFromRawBytesHex AsTxId (TSE.encodeUtf8 txHash) of
          Just txid -> case readMaybe (T.unpack index) of
            Just txindex ->  pure $ UtxoIdModal  (txid, TxIx txindex)
            Nothing -> fail $ "Failed to parse txIndex in " ++ T.unpack v
          Nothing -> fail $ "Failed to parse value as txHash " ++ T.unpack txHash
      _ -> fail $ "Expected to be of format 'txId#index' got :" ++ T.unpack v
  parseJSON _ = fail "error"



-- newtype AddressModal= AddressModal (AddressInEra AlonzoEra) deriving Show
instance FromJSON AddressModal where
  parseJSON (String s)=  case deserialiseAddress (AsAddressInEra AsAlonzoEra) s of
      Nothing -> fail "Invalid address string. Couldn't be parsed as valid address for alonzo era"
      Just aie -> pure $ AddressModal aie
  parseJSON _ = fail "Expected Address to be String"

instance ToJSON AddressModal where
  toJSON (AddressModal addr)= String $ serialiseAddress  addr

-- newtype SignKeyModal= SignKeyModal (SigningKey PaymentKey) deriving Show
instance FromJSON SignKeyModal where
  parseJSON (String s) = parseSignKey s <&> SignKeyModal
  parseJSON _ = fail "Expected signKey to be string type"

instance ToJSON SignKeyModal where
  toJSON  (SignKeyModal s) = String $ serialiseToBech32 s

instance ToJSON CostModal where
  toJSON (CostModal (AssetId policy token,Quantity value))= object ["policyId" .= policy,"name" .=token, "amount" .=value]
  toJSON (CostModal (AdaAssetId,value ))         = object [ "policyId"  .= (""::T.Text), "name"   .= (""::T.Text),"amount" .=value]

instance FromJSON ShareModal where
  parseJSON  (Object o) = curry ShareModal
                            <$> (o .: "address" <&> (\(AddressModal x) -> x))
                            <*> o .: "npercent"

  parseJSON  _ = fail "Expected ShareModal object"



-- WitnessSet raw           : a10081825820b004cba76275ee90b44de0bee3edf2f69b77a3936c59879536bd0d3fcbc25e635840e45c7bc0c8f2a079f64223b97ac8296d7d1fa22c23be49af1d1fd49e0083aa475bd5bfdf601511a7b9dcf26fb18c0e31f02b289110a7af2e898dbb4494ef180f
-- new VkeyWitness raw      : 825820b004cba76275ee90b44de0bee3edf2f69b77a3936c59879536bd0d3fcbc25e635840e45c7bc0c8f2a079f64223b97ac8296d7d1fa22c23be49af1d1fd49e0083aa475bd5bfdf601511a7b9dcf26fb18c0e31f02b289110a7af2e898dbb4494ef180f
-- newVkeyWitness signature : e45c7bc0c8f2a079f64223b97ac8296d7d1fa22c23be49af1d1fd49e0083aa475bd5bfdf601511a7b9dcf26fb18c0e31f02b289110a7af2e898dbb4494ef180f
-- newVkeyWWitness vkey     : 5820b004cba76275ee90b44de0bee3edf2f69b77a3936c59879536bd0d3fcbc25e63
-- newVkeyWiness pubKeyHash : f735cdaa2ae360ce67e27cd2f6038a44c77bf3ede94bd144674d34e6
-- newVkeyWitness pubkey raw: b004cba76275ee90b44de0bee3edf2f69b77a3936c59879536bd0d3fcbc25e63
-- newVkeyWWitness publicKey: ed25519_pk1kqzvhfmzwhhfpdzduzlw8m0j76dh0gund3vc09fkh5xnlj7zte3s7huq08
instance FromJSON WitnessModal where
  parseJSON  (String str) = do
    let cborHexText = case T.stripPrefix "a10081" str of
                    Nothing -> str
                    Just txt ->  T.concat ["8200",txt]
    case convertText  cborHexText of
      Nothing ->  fail "Witness string is not hex encoded"
      Just (Base16 bs) -> case  deserialiseFromCBOR (AsKeyWitness AsAlonzoEra) bs of
        Left e  -> fail $ "Witness string: Invalid CBOR format : " ++ show e
        Right witness -> pure $ WitnessModal witness

  parseJSON _ = fail "Expecte Witness Modal cbor hex string"

tryParseWitness str= case convertText  str of
      Nothing ->  fail "Witness string is not hex encoded"
      Just (Base16 bs) -> case  deserialiseFromCBOR (AsKeyWitness AsAlonzoEra) bs of
        Left e  -> fail $ "Witness string: Invalid CBOR format : " ++ show e
        Right witness -> pure $ WitnessModal witness


instance FromJSON TxModal where
  parseJSON (String txStr) = do
    case convertText txStr of
      Nothing -> fail "Tx string is not hex encoded"
      Just (Base16 bs) -> case deserialiseFromCBOR (AsTx AsAlonzoEra ) bs of
        Left  e -> fail $ "Tx string: Invalid CBOR format : "++ show e
        Right tx -> pure $ TxModal tx
  parseJSON _ = fail "Expected Tx cbor hex string"



signKeyParser v key = case H.lookup key v of
    Nothing -> fail $ "missing key \""++ T.unpack key++"\" in the json value"
    Just v -> case fromJSON v of
      Error s -> fail $ "expected bench32 encoded SignKey for key \"" ++ T.unpack key ++"\" "
      Success v -> parseSignKey v

addressParser v key = addressParser' v key (fail $"missing key \"" ++ T.unpack key ++ "\" in the json object")


addressParser' v key _def = case H.lookup key v of
  Nothing -> _def
  Just v -> case fromJSON v of
    Error s -> fail $ "expected address string for key \""++T.unpack key ++"\""
    Success v-> case deserialiseAddress (AsAddressInEra AsAlonzoEra) v of
      Nothing -> fail "Invalid address string. Couldn't be parsed as valid address for alonzo era"
      Just aie -> pure aie

scriptDataParser v key = case H.lookup key v of
  Nothing -> fail $"missing key \"" ++ T.unpack key ++ "\" if type ScriptData in json object"
  Just v -> doParsing v
  where
    doParsing (String v) =  parseScriptData  v
    doParsing (Object o )=case scriptDataFromJson ScriptDataJsonDetailedSchema  (Object o) of
       Left sdje -> case sdje of
        ScriptDataJsonSchemaError va sdjse -> fail $  "Wrong schema" ++ show sdjse
        ScriptDataRangeError va sdre -> fail $  "Invalid data " ++ show sdre
       Right sd -> pure  sd
    doParsing _  = fail "Script data Must be either string or object"

instance FromCBOR  UtxoIdModal where
  fromCBOR = do
    CollateralWrapper ((txid,txix),(_,_)) <- fromCBOR
    case deserialiseFromRawBytes AsTxId txid of
      Nothing -> fail "die"
      Just ti -> pure $ UtxoIdModal (ti,TxIx txix)

parseCollateral ::  MonadFail m => Text -> m UtxoIdModal
parseCollateral txt = do
  case convertText  txt of
    Nothing ->  fail "Collateral string is not hex encoded"
    Just (Base16 bs) -> case decodeFull $ fromStrict bs of
      Left e -> fail "Collateral string : Invalid CBOR format "
      Right (UtxoIdModal m) -> pure $ UtxoIdModal m

collateralParser (String s) = parseCollateral s
collateralParser _ = fail "Expected collateral format to be CBOR hex string"

newtype CollateralWrapper = CollateralWrapper ((ByteString,Word ),(ByteString,Word)) deriving Show
instance FromCBOR CollateralWrapper where
  fromCBOR = do
    CollateralWrapper <$> fromCBOR


--  data Decoder s a

--  -- for, e.g., safe in-place mutation during decoding
--  liftST      :: ST s a -> Decoder s a

--  -- primitive decoders
--  decodeWord  :: Decoder s Word
--  decodeBytes :: Decoder s ByteString
--  -- et cetera
newtype Witnesses = Witnesses [KeyWitness AlonzoEra]

-- instance FromCBOR Witnesses where
--   fromCBOR = do
--     CBOR.CBORGroup  [v] <- fromCBOR
--     pure $ head v

-- parseWitness :: MonadFail m => Text -> m ([KeyWitness AlonzoEra])
-- parseWitness txt =  case convertText  txt of
--     Nothing ->  fail "Witness string is not hex encoded"
--     Just (Base16 bs) -> case deserialiseFromCBOR ([AsWi AsAlonzoEra]) bs of
--         Left de -> fail $ show de
--         Right kw -> pure kw

-- magic :: IO ()
-- magic = do
--   w <-  parseWitness "a10081825820b004cba76275ee90b44de0bee3edf2f69b77a3936c59879536bd0d3fcbc25e63584043e49031662da6046e07b93dd9683b603191297c8e61f773d5d1ee2124dd86ec0727262a0ee968b619f2c99e02460eb149887c7cc408899673995fa90db52b09"
--   print w
