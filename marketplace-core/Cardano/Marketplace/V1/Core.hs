{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE AllowAmbiguousTypes #-}
module Cardano.Marketplace.V1.Core
where

import Control.Monad.IO.Class (MonadIO (liftIO))
import Cardano.Kuber.Util hiding (toHexString)
import Cardano.Marketplace.Common.TextUtils ( toHexString, pkhToAddr )
import qualified Data.Map as Map
import Cardano.Api
import Data.ByteString (ByteString)
import qualified Data.ByteString.Short as SBS
import qualified Data.ByteString.Lazy as LBS
import PlutusTx.Prelude (BuiltinByteString, fromBuiltin, toBuiltin)
import Plutus.V1.Ledger.Value (AssetClass(AssetClass), CurrencySymbol (CurrencySymbol), TokenName (TokenName), singleton, assetClassValue, assetClassValueOf)
import qualified Plutus.V1.Ledger.Value as PlutusValue
import qualified Data.ByteString as BS
import Cardano.Api.Shelley
    ( PlutusScript(PlutusScriptSerialised), toPlutusData, toShelleyAddr, Lovelace (Lovelace), fromPlutusData, Address (ShelleyAddress), TxBody (ShelleyTxBody), ProtocolParameters (protocolParamMinUTxOValue), toAlonzoData, fromShelleyAddr, fromShelleyTxOut )
import Codec.Serialise (serialise)
import Control.Exception (throw, SomeException (SomeException), try, throwIO, Exception (fromException))
import Plutus.V1.Ledger.Api (fromData, toData, Data (Map), POSIXTime (POSIXTime), lowerBound, upperBound, ToData (toBuiltinData), PubKeyHash (PubKeyHash))
import qualified Plutus.V1.Ledger.Api (TxOut (txOutValue))
import Cardano.Kuber.Api
import Cardano.Marketplace.V1.RequestModels
import Data.Text.Conversions (toText, UTF8 (UTF8), FromText (fromText), convertText)
import Data.Functor ((<&>))
import Data.Aeson (encode, json')
import Data.Text.Lazy.Encoding (decodeUtf8)
import Data.Text.Lazy (unpack, intercalate, toStrict)
import qualified Data.List as L
import qualified Data.ByteString.Char8 as CBS

import qualified Cardano.Ledger.Alonzo.Tx as AlonzoTx
import Cardano.Marketplace.V1.ServerRuntimeContext (RuntimeContext (..), AuctionConfig (acOperator, acTreasury, acFee))
import Cardano.Marketplace.Common.ConsoleWritable
    ( ConsoleWritable(toConsoleText, toConsoleTextNoPrefix) )
import Data.Text(Text)
import qualified Data.Text.Encoding as TSE
import Data.Maybe
    ( isNothing, mapMaybe, fromMaybe, isJust, maybeToList )
import qualified Data.ByteString.Lazy as TLE
import qualified Data.Text as T
import qualified Control.Monad.State as State
import Control.Monad.State (State, StateT (StateT))
import qualified Control.Monad.IO.Class as IOClass
import GHC.Conc
import Control.Monad.Reader
import Servant (Handler(Handler))
import qualified Data.Set as Set
import qualified Data.Foldable as Foldable
import qualified Cardano.Ledger.Alonzo.TxBody as AlonzoBody
import Plutus.V1.Ledger.Scripts (unValidatorScript)
import Plutus.Contracts.V1.Marketplace
import Plutus.Contracts.V1.Auction ( auctionValidator, Auction (..),auctionScript, AuctionRedeemer (Bid,ClaimBid), auctionHundredPercent, aPaymentReceiversValue)
import qualified Plutus.Contracts.V1.Auction  as Auction
import Plutus.V1.Ledger.Interval
import qualified PlutusTx.AssocMap as AssocMap
import qualified PlutusTx.Prelude as PlutusPrelude
import Cardano.Ledger.Keys (KeyPair(sKey))
import qualified Debug.Trace as Debug
import qualified Data.ByteString.Lazy.Char8 as BSChar8
import Cardano.Kuber.Api
import qualified Plutus.V1.Ledger.Api as PlutusTx
import Plutus.V1.Ledger.Contexts (txSignedBy)

putStrLn' :: [Char] -> IO ()
putStrLn' v =pure ()

queryUtxosOf :: ChainInfo v => v   -> AddressModal -> IO (UTxO AlonzoEra)
queryUtxosOf  ctx (AddressModal addr)= do
  -- getAddrAnyFromEra
  utxos <- queryUtxos (getConnectInfo  ctx) $ Set.singleton (case addr of { AddressInEra atie ad -> toAddressAny ad } )
  case utxos of
    Left err -> throwIO err
    Right utxos' -> pure utxos'

getBalance :: ChainInfo v => v   -> String -> IO BalanceResponse
getBalance ctx addrStr = do
  addr <- case deserialiseAddress AsAddressAny  $ T.pack addrStr of
    Nothing -> throw $  FrameworkError ParserError "Invalid address"
    Just aany      -> pure aany

  utxos <- queryUtxos (getConnectInfo  ctx) $ Set.singleton addr
  case utxos of
    Left err -> throwIO err
    Right utxos' -> pure $ BalanceResponse utxos'

queryMarketUtxos :: ChainInfo v => v -> Market -> IO (UTxO AlonzoEra)
queryMarketUtxos ctx market = do
  utxos <- queryUtxos (getConnectInfo  ctx) $ Set.singleton (toAddressAny $ marketAddressShelley  market (getNetworkId ctx))
  case utxos of  
    Left err -> throwIO err
    Right utxos' -> pure utxos'

payToAddress :: DetailedChainInfo -> PaymentReqModel -> IO TxResponse
payToAddress dcInfo (PaymentReqModel sKey preqReceivers mPayer mChangeAddr sendEverything ignoreTinySurplus ignoreTinyinSufficient)=do
  let operation = mconcat $ map    (\(PaymentUtxoModel val addr feeUtxo changeUtxo) -> txPayTo  addr val) preqReceivers
  txBodyE <- txBuilderToTxBodyIO dcInfo operation
  case txBodyE of 
    Left fe -> throwIO fe
    Right txBody -> pure $ mkSignedResponse sKey txBody

submitTx :: ChainInfo v => v    -> SubmitTxModal -> IO TxResponse
submitTx ctx (SubmitTxModal tx  mWitness) =do
  let tx'= case mWitness of
                Nothing ->   tx
                Just kw ->  makeSignedTransaction (kw:getTxWitnesses tx) txbody
      txbody=getTxBody tx
  executeSubmitTx (getConnectInfo ctx) tx'
  pure $ TxResponse tx' []

marketScriptAddr dcInfo market = makeShelleyAddressInEra
                       (getNetworkId dcInfo)
                       (PaymentCredentialByScript $ hashScript $ PlutusScript PlutusScriptV1 $ marketScriptSerialised market)
                       NoStakeAddress


placeOnMarket :: DetailedChainInfo -> Market -> SellReqBundle   -> IO SaleCreateResponse
placeOnMarket dcInfo market  (SellReqBundle context sales topLevel) =do
    tcxa@(TxContextAddresses senderAddr payerAddr  changeAddr receiverAddr addrLookup) <-populateAddresses' context (getNetworkId dcInfo) Nothing
    Debug.traceM $ "context       : " ++ show context
    Debug.traceM $ "parsedContext : " ++ show tcxa
    Debug.traceM $ "changeAddr    : " ++ T.unpack (serialiseAddress changeAddr)
    sellerPkh <- addrInEraToPkh senderAddr
      
    constraints <- mapM (toConstraint sellerPkh ) sales

    txbody <- txBuilderToTxBodyIO dcInfo $ foldMap fst constraints
    case txbody of 
      Left fe -> throwIO fe
      Right tb -> do
        let TxResponse _tx _ =mkTxResponse'' context tb
        pure $ SaleCreateResponse _tx (map snd constraints) topLevel
      
  where
    toConstraint  sellerPkh (SellReqModel (CostModal asset) parties (CostModal (costAsset, Quantity costAmount))  isSecondary) = do
        partiesData <- mapM toParty parties
        let lockedValue =valueFromList [asset]
            txOperation= txPayToScript (marketScriptAddr dcInfo market) lockedValue
            AssetClass (currency,tokenName) = toPlutusAssetClass costAsset
            directSale=DirectSale {
              dsSeller= sellerPkh,
              dsSplits= partiesData,
              dsPaymentCurrency=  currency ,
              dsPaymentTokenName=tokenName,
              dsCost = costAmount,
              dsType=if isSecondary then Secondary  else Primary
            }
            scriptData = fromPlutusData $ toData directSale
        pure (txOperation $  hashScriptData scriptData, scriptData)
    toParty (ShareModal (addr,v))=do
            _pkh <- addrInEraToPkh  addr
            pure (_pkh, v)

-- TODO withdraw not supported currently
-- withdrawCommand ::RuntimeContext  -> WithdrawReqModel  -> IO TxResponse
-- withdrawCommand  rCtx   (WithdrawReqModel  scData mUtxo mAsset  maybeReceiver  mCollateral) =do
--   let conn=getConnectInfo  networkCtx
--       networkCtx  = runtimeContextCardanoConn  rCtx
--       network = getNetworkId networkCtx
--       market = runtimeContextMarket rCtx

--       marketAddressAny= toAddressAny $ marketAddressShelley market network
--   utxos <- do
--     utxosE <- queryUtxos conn $ Set.singleton $ toAddressAny $ marketAddressShelley market network
--     case utxosE of
--       Left err -> throwIO err
--       Right utxos' -> pure utxos'

--   directSale  <- case fromData $ toPlutusData scData of
--     Just d -> pure d
--     Nothing -> fail $ "Withdraw: Failed to convert scriptData to Directsale"  ++ (case mAsset of
--                                 Nothing -> ""
--                                 Just am -> "\n " ++ show (unAssetModal am))
--   (txin,txout) <- performQueryScriptUtxo networkCtx marketAddressAny scData (mAsset <&> unAssetModal) mUtxo  "Withdraw"
--   let operation=case mCollateral of
--         Nothing -> txRedeemUtxoWithValidator  (UTxO $ Map.singleton txin txout) (marketValidator market) directSale Withdraw
--         Just (UtxoIdModal v) -> txRedeemUtxoWithValidator  (UTxO $ Map.singleton txin txout) (marketValidator market) directSale Withdraw
--                             <>  txAddCollateral (uncurry TxIn v)
--   sellerAddress <- case  maybeReceiver of
--       Just r -> do
--         case addrInEraToPkh  r of
--           Just pkh  -> if pkh ==dsSeller directSale
--                           then
--                             pure r
--                           else failWithMessage directSale  "Withdraw: Reveriver address provided but the keyHash doesn't match with seller"
--           Nothing -> failWithMessage directSale "Withdraw: Unexpected Error converting address to PubKeyHash"
--       Nothing ->  pkhToAddr network (dsSeller directSale)
--   txbody <- mkTx networkCtx operation sellerAddress
--   pure $ TxResponse (makeSignedTransaction [] txbody) []
--   where
--     failWithMessage :: MonadFail m => DirectSale  -> String -> m a
--     failWithMessage ds m =fail $ m ++"\n  " ++ show ds ++ (case mAsset of
--                                 Nothing -> ""
--                                 Just am -> "\n " ++ show (unAssetModal am))

--     -- handleError (TxValidationError error) = fail $ show
-- operatorWithdraw :: RuntimeContext   -> OperatorWithdrawModel  -> IO TxResponse
-- operatorWithdraw  aRuntime (OperatorWithdrawModel scData mUtxo mAsset sKey maybeReceiver) =do
--   let networkCtx = runtimeContextCardanoConn aRuntime
--       conn=networkCtxConn   networkCtx
--       network = networkCtxNetwork networkCtx
--       market = runtimeContextMarket aRuntime
--       marketAddressAny= toAddressAny $ marketAddressShelley market network
--       payerAddress = skeyToAddrInEra sKey network
--   uMap<-queryUtxos conn $ (case payerAddress of { AddressInEra atie ad -> toAddressAny ad } )
--   directSale  <- case fromData $ toPlutusData scData of
--     Just d -> pure d
--     Nothing -> fail $ "Withdraw: Failed to convert scriptData to Directsale"  ++ (case mAsset of
--                                 Nothing -> ""
--                                 Just am -> "\n " ++ show (unAssetModal am))
--   (txin,txout) <- performQueryScriptUtxo networkCtx marketAddressAny scData (mAsset <&> unAssetModal) mUtxo "Operator Withdraw"

--   sellerAddress <- case  maybeReceiver of
--       Just r -> do
--         case addrInEraToPkh  r of
--           Just pkh  -> if pkh ==dsSeller directSale
--                           then
--                             pure r
--                           else failWithMessage directSale  "Withdraw: Receriver address provided but the kyHash doesn't match with seller"
--           Nothing -> failWithMessage directSale "Withdraw: Unexpected Error converting address to PubKeyHash"
--       Nothing ->  pkhToAddr network (dsSeller directSale)

--   operatorOperations <- txOperatorActions aRuntime
--   let operation =
--             txRedeemUtxoWithValidator  (UTxO $ Map.singleton txin txout) (marketValidator market) directSale Withdraw
--           <> txConsumeUtxos uMap
--           <> operatorOperations
--   txbody <- mkTxWithChange networkCtx operation payerAddress sellerAddress
--   pure $ mkTxResponse_ [runtimeContextOperatorSkey aRuntime,sKey] txbody
--   where
--     failWithMessage :: MonadFail m => DirectSale  -> String -> m a
--     failWithMessage ds m =fail $ m ++"\n  " ++ show ds ++ (case mAsset of
--                                 Nothing -> ""
--                                 Just am -> "\n " ++ show (unAssetModal am))


--TODO Auction Part
-- placeOnAuction :: RuntimeContext -> StartAuctionBundle    -> IO AuctionCreateResponse
-- placeOnAuction ctx  (StartAuctionBundle context auctions topLevel)  =do
--     let aConfig = runtimeContextAuctionConfig ctx
--         networkCtx = runtimeContextCardanoConn ctx
--     resolvedContext@TxContextAddresses{txContextChangeAddr,txContextPayerAddr}<-populateAddresses' context (getNetworkId networkCtx) Nothing
--     auctionActions <- mapM (toOperation (getNetworkId  networkCtx) aConfig resolvedContext) auctions

--     txBody <- mkTxWithChange networkCtx (mconcat $  map fst auctionActions) txContextPayerAddr txContextChangeAddr
--     let TxResponse tx _= mkTxResponse'' context txBody
--     pure $ AuctionCreateResponse tx (map snd auctionActions) topLevel
--   where
--     toOperation network aConfig (TxContextAddresses senderAddr payerAddr changeAddr receiverAddr knownAddresses)
--                 (StartAuctionModel  (CostModal asset) parties (CostModal (bidAsset, Quantity startBid)) mStartTime mEndTime minIncrement)= do
--         partiesData <- mapM toParty parties
--         sellerPkh <- addrInEraToPkh senderAddr
--         let lockedValue =valueFromList [asset]
--             auction=Auction {
--               aOperator = acOperator aConfig,
--               aTreasuryAddress = acTreasury aConfig,
--               aPlatformFee =acFee aConfig,
--               aOwner =sellerPkh,
--               aSplits=partiesData,
--               aAssetClass = toPlutusAssetClass bidAsset,
--               aMinBid = startBid,
--               aMinIncrement =minIncrement, -- min increment  from previous auction per bid
--               aDuration = validityInterval, -- Auction duration
--               aValue=  assetClassValue (toPlutusAssetClass $ fst asset) (case snd asset of { Quantity n -> n } )  -- The value that's placed on Auction. this is what winner gets.
--             }
--             lockedDatum =  sellerPkh
--             auctionAddr = auctionAddressShelley auction network
--             auctionRes=AuctionResponse (auctionScriptPlutus auction) (fromPlutusData $ toData lockedDatum ) (auctionAddressShelley auction  network) auction
--             validityInterval=case mStartTime of
--               Nothing -> case mEndTime of
--                 Nothing -> PlutusPrelude.Nothing
--                 Just endTime ->  PlutusPrelude.Just $ to $ POSIXTime endTime
--               Just startTime -> case mEndTime of
--                 Nothing -> PlutusPrelude.Just $ from $ POSIXTime startTime
--                 Just endTime ->  PlutusPrelude.Just $ Interval (lowerBound $ POSIXTime startTime) (upperBound $ POSIXTime endTime )
--         pure $  (txPayToScript (auctionValidator  auction)  lockedDatum lockedValue,auctionRes)
--     toParty (ShareModal (addr,v))=do
--             _pkh <- addrInEraToPkh  addr
--             pure (_pkh, v)

-- bidOnAuction :: RuntimeContext  -> BidReqModel    -> IO TxResponse
-- bidOnAuction rCtx (BidReqModel  auction context mUtxoId mAsset scriptData mCollateral mBid bidEverythig) = do
--   let ctx = runtimeContextCardanoConn rCtx
--       aConfig= runtimeContextAuctionConfig rCtx
--   networkCtx<- toFullNetworkContext ctx
--   let network=networkCtxNetwork networkCtx
--       pParam= case networkCtx of { DetailedChainInfo _ _ param _ _ -> param }
--       func add v = calculateTxoutMinLovelace
--   minAdaCalc <-case calculateTxoutMinLovelaceFunc pParam of
--     Nothing ->  fail "MinUtxo Lovelace calculation failed due to missing protocolParam"
--     Just f -> pure  (\add v -> f (TxOut add (TxOutValue MultiAssetInAlonzoEra v) TxOutDatumNone  ) )
--   TxContextAddresses senderAddr payerAddr changeAddr receiverAddr addressLookup <-populateAddresses' context (networkCtxNetwork networkCtx) Nothing

--   lastBidder  <- unMaybe "Failed to convert datum to DirectSale"  (fromData $ toPlutusData scriptData)

--   auctionAsset <-unEither $ auctionAssetId auction

--   scriptUtxos <- queryUtxos (networkCtxConn  ctx) (auctionAddressAny ctx auction)
--   (txin,txout) <- performQueryScriptUtxo networkCtx (auctionAddressAny ctx auction) scriptData mAsset mUtxoId "Bid Auction"

--   newBidderPkh <- addrInEraToPkh senderAddr
--   let operations= txRedeemUtxo (UTxO $ Map.singleton txin txout) (auctionScriptPlutus auction) lastBidder Bid
--         <> txPayToScript (auctionScriptPlutus auction) newBidderPkh valueReLocked
--         <> ( if case selectAsset auctionUtxoValue auctionAsset of { Quantity n -> n<=0 }
--               then mempty
--               else (case Map.lookup lastBidder addressLookup of
--                         Nothing -> txPayToPkh lastBidder valueForLastBidder
--                         Just aie -> txPayTo aie valueForLastBidder
--               )
--             )
--         <> timeRange
--       timeRange=case aDuration auction of
--         PlutusPrelude.Just (Interval (LowerBound (Finite (POSIXTime start)) _) (UpperBound (Finite  (POSIXTime end)) _)) -> txValidPosixTimeRange (start  + 1000) (end-1000) -- increase starting time just in case.
--         PlutusPrelude.Just (Interval (LowerBound NegInf _) (UpperBound (Finite  (POSIXTime end)) _)) -> txValidUntilPosixTime (end-1000)
--         PlutusPrelude.Just (Interval (LowerBound (Finite (POSIXTime start)) _) (UpperBound PosInf  _)) -> txValidFromPosixTime  (start+1000)
--         _ -> mempty
--       valueForLastBidder= valueFromList [
--         (auctionAsset,  selectAsset auctionUtxoValue auctionAsset
--                         <> Quantity ( negate $ assetClassValueOf (aValue auction) (aAssetClass auction)))
--                     ]
--       valueReLocked = auctionUtxoValue <> valueFromList [
--                         (auctionAsset, case mBid of
--                                             Nothing -> Quantity (aMinBid auction)
--                                             Just n -> (- (selectAsset auctionUtxoValue auctionAsset)) <> Quantity n )
--                         ]
--       auctionUtxoValue =case txout of { TxOut aie tov tod -> txOutValueToValue tov }
--   txBody <- mkTxWithChange ctx operations payerAddr changeAddr
--   print txBody

--   pure $ mkTxResponse' context txBody [newBidderPkh ]


-- finalizeAuction :: Bool ->  RuntimeContext  -> FinalizeAuctionModel     -> IO TxResponse
-- finalizeAuction asOperator  ctx (FinalizeAuctionModel auction  context mSellerDepositSkey mUtxoId mAsset scriptData mCollateral) = do
--   networkCtx<- toFullNetworkContext  $ runtimeContextCardanoConn  ctx
--   let aConfig = runtimeContextAuctionConfig ctx
--       network=networkCtxNetwork networkCtx
--       pParam= case networkCtx of { DetailedChainInfo _ _ param _ _ -> param }
--       func add v = calculateTxoutMinLovelace
--   minAdaCalc <-case calculateTxoutMinLovelaceFunc pParam of
--     Nothing ->  fail "MinUtxo Lovelace calculation failed due to missing protocolParam"
--     Just f -> pure  (\add v -> f (TxOut add (TxOutValue MultiAssetInAlonzoEra v) TxOutDatumNone  ) )
--   -- currentTime <- ge
--   let
--     timeRange=case aDuration auction of
--         Just (Interval _ (UpperBound (Finite  (POSIXTime end)) _)) -> txValidFromPosixTime  (end  + 1000)
--         _ -> mempty
--   TxContextAddresses senderAddr payerAddress changeAddr receiverAddr  addressLookup <-populateAddresses' context (networkCtxNetwork networkCtx) Nothing
--   lastBidderPkh  <- unMaybe "Failed to convert datum to BidderAddress"  (fromData $ toPlutusData scriptData)
--   if lastBidderPkh == (aOwner auction) then fail "Error: Finalize on a auction with no bid" else pure ()

--   lastBidder <- case Map.lookup lastBidderPkh addressLookup of
--       Nothing   -> pkhToAddr network lastBidderPkh
--       Just aie  -> pure aie
--   auctionAsset <-unEither $ auctionAssetId auction
--   (txin,txout) <- performQueryScriptUtxo networkCtx (auctionAddressAny networkCtx auction) scriptData mAsset mUtxoId "Bid Auction"

--   (sellerExtraAmount,extraInputs)<-case mSellerDepositSkey of
--     Nothing -> pure ( valueFromList [],mempty)
--     Just sk -> do
--       depositAddrUtxos <- queryUtxosOf networkCtx $ AddressModal $ skeyToAddrInEra  sk network
--       pure $ (utxoValueSum depositAddrUtxos,txConsumeUtxos depositAddrUtxos <>txAddSignature sk)

--   auctionOwner <- case Map.lookup (aOwner auction) addressLookup of
--     Nothing   -> pkhToAddr network (aOwner auction)
--     Just aie  -> pure aie

--   let
--       valueOnAuction = fromPlutusValue (aValue auction)
--       auctionUtxoValue =case txout of { TxOut aie tov tod -> txOutValueToValue tov }
--       (platformFee, payments)= aPaymentReceiversValue auction auctionAsset (negateValue valueOnAuction <> auctionUtxoValue) sellerExtraAmount
--   sellerPayments <- mapM    (\(pkh,v) -> do
--                       case Map.lookup pkh addressLookup of
--                         Nothing ->do
--                           addr <-  pkhToAddr network pkh
--                           pure $ txPayTo addr v
--                         Just aie -> pure $  if aie /= changeAddr
--                                               then txPayTo aie ( ensureMinAda (minAdaCalc aie) v)
--                                               else mempty
--                   ) payments
--   operatorActions <-  if asOperator then txOperatorActions ctx else pure mempty
--   let treasuryAddr=runtimeContextTreasury   ctx
--       operations=
--            operatorActions
--         <> txRedeemUtxo (UTxO $ Map.singleton txin txout) (auctionScriptPlutus auction) lastBidderPkh ClaimBid
--         <> txPayTo  treasuryAddr (ensureMinAda (minAdaCalc treasuryAddr) $ valueFromList [(auctionAsset,Quantity platformFee)])
--         <> (if lastBidder /=changeAddr then  txPayTo lastBidder ( ensureMinAda (minAdaCalc lastBidder) valueOnAuction) else mempty)
--         <> mconcat sellerPayments
--         <> timeRange
--         <> extraInputs

--   txBody <- mkTxWithChange networkCtx operations payerAddress changeAddr
--   print body
--   pure $ _mkTxResponse (maybeToList (txContextAddressesReqSignKey context) ++ maybeToList mSellerDepositSkey ++ ([runtimeContextOperatorSkey ctx | asOperator] )) body []
--   where
--     _mkTxResponse :: [SigningKey PaymentKey] -> TxBody AlonzoEra -> [Maybe PubKeyHash ] -> TxResponse
--     _mkTxResponse=mkTxResponse
--     ensureMinAda  f  value =
--       if diff > 0
--       then value <> lovelaceToValue (Lovelace diff )
--       else value
--       where
--         diff= minLovelace - currentLovelace
--         minLovelace= case f $ value <> lovelaceToValue (Lovelace 1_000_000)of {Lovelace n -> n}
--         currentLovelace =  case selectAsset value AdaAssetId of {Quantity n -> n}
--     aPaymentReceiversValue ::  Auction ->AssetId -> Value->Value -> (Integer,[(PubKeyHash,Value)])
--     aPaymentReceiversValue  a@Auction{aOwner,aPlatformFee } biddingAsset closingValue sellerExtra =
--       if ownerPaymentInt /=0
--         then (platformFee,( aOwner, ownerValue) : partiesValue)
--          else (platformFee,partiesValue)
--       where
--         ownerPaymentInt = case selectAsset ownerValue AdaAssetId of { Quantity n -> n }
--         ownerValue = valueFromList [(biddingAsset, Quantity $ sellerPart - sum (map snd partiesPayment))] <>sellerExtra
--         partiesValue = map (\(pkh,v)-> (pkh,valueFromList [ (biddingAsset, Quantity v)])) partiesPayment
--         partiesPayment=map (\(pkh,v) ->(pkh,(v*sellerPart)`div` auctionHundredPercent)) (aSplits a)
--         bidContent= case selectAsset closingValue biddingAsset of { Quantity n -> n }
--         sellerPart= (bidContent * (auctionHundredPercent - aPlatformFee  )) `div` auctionHundredPercent
--         platformFee = bidContent - sellerPart


-- operatorCancelAuction :: RuntimeContext   -> OperatorCancelAuctionModel   -> IO TxResponse
-- operatorCancelAuction  aRuntime (OperatorCancelAuctionModel addrContext auction scData mUtxo mAsset  ) =do
--   let networkCtx = runtimeContextCardanoConn aRuntime
--       conn=networkCtxConn   networkCtx
--       network = networkCtxNetwork networkCtx
--       auctionAddressAny= toAddressAny $ auctionAddressShelley auction network
--   aDatum <- case fromData $ toPlutusData scData of
--     Just pkh -> if pkh ==aOwner auction
--                           then
--                             pure $ pkh
--                           else failWithMessage   "Withdraw : Auction has bids in it"
--     Nothing -> fail $ "Withdraw: Failed to convert scriptData to Auction"  ++ (case mAsset of
--                                 Nothing -> ""
--                                 Just am -> "\n " ++ show  am)
--   ctxa@(TxContextAddresses senderAddr payerAddr changeAddr receiverAddr addressLookup) <-case populateAddresses addrContext network (Just $ aOwner auction)  of
--     Left s -> fail s
--     Right tca -> pure tca
--   sellerAddr <- case Map.lookup (aOwner auction) addressLookup of
--       Nothing -> pkhToAddr  network (aOwner auction)
--       Just aie -> pure aie
--   (txin,txout) <- performQueryScriptUtxo networkCtx auctionAddressAny scData mAsset mUtxo "Operator Withdraw"


--   uMap<-queryUtxos conn $ (case payerAddr of { AddressInEra atie ad -> toAddressAny ad } )


--   operatorActions <- txOperatorActions aRuntime
--   let operation =
--             txRedeemUtxoWithValidator  (UTxO $ Map.singleton txin txout) (auctionValidator  auction) aDatum Auction.Withdraw
--         <> txConsumeUtxos uMap
--         <> operatorActions

--   txbody <- mkTxWithChange networkCtx operation payerAddr sellerAddr
--   pure $ mkTxResponse  (case txContextAddressesReqSignKey addrContext of
--                         Nothing -> [runtimeContextOperatorSkey aRuntime]
--                         Just sk -> [sk,runtimeContextOperatorSkey  aRuntime]) txbody ([]::[Maybe PubKeyHash])
--   where
--     failWithMessage :: MonadFail m =>   String -> m a
--     failWithMessage  m =fail $ m ++"\n  " ++ (case mAsset of
--                                 Nothing -> ""
--                                 Just am -> "\n " ++ show  am)


-- cancelAuctionCommand :: RuntimeContext   -> CancelAuctionModel   -> IO TxResponse
-- cancelAuctionCommand  aRuntime (CancelAuctionModel context auction scData mUtxo mAsset ) =do
--   let networkCtx = runtimeContextCardanoConn aRuntime
--       conn=networkCtxConn   networkCtx
--       network = networkCtxNetwork networkCtx
--       marketAddressAny= toAddressAny $ auctionAddressShelley auction network

--   aDatum <- case fromData $ toPlutusData scData of
--     Just  pkh -> if pkh ==aOwner auction
--                           then
--                             pure  pkh
--                           else fail   "Withdraw : Auction has bids in it"
--     Nothing -> fail $ "Withdraw: Failed to convert scriptData to Auction"  ++ (case mAsset of
--                                 Nothing -> ""
--                                 Just am -> "\n " ++ show  am)
--   (txin,txout) <- performQueryScriptUtxo networkCtx marketAddressAny scData mAsset mUtxo "Cancel Auction"
--   TxContextAddresses senderAddr payerAddr changeAddr receiverAddr addressLookup <-case populateAddresses context network (Just $ aOwner auction)  of
--     Left s -> fail s
--     Right tca -> pure tca

--   let operation =
--             txRedeemUtxoWithValidator  (UTxO $ Map.singleton txin txout) (auctionValidator  auction) aDatum Auction.Withdraw

--   txbody <- mkTxWithChange networkCtx operation payerAddr changeAddr
--   pure $ mkTxResponse'' context txbody
--   where
--     failWithMessage :: MonadFail m => DirectSale  -> String -> m a
--     failWithMessage ds m =fail $ m ++"\n  " ++ show ds ++ (case mAsset of
--                                 Nothing -> ""
--                                 Just am -> "\n " ++ show  am)

--     toVal (TxOut _ (TxOutValue _ v) _) = v
--     toVal (TxOut _ (TxOutAdaOnly _ l) _) = lovelaceToValue l


mkTxResponse :: ToData a =>[SigningKey PaymentKey]-> TxBody AlonzoEra -> [a] -> TxResponse
mkTxResponse skeys txBody datums=do
    TxResponse (makeSignedTransaction (map toWitness skeys) txBody ) $  map (fromPlutusData . toData ) datums
  where
    toWitness sk= makeShelleyKeyWitness txBody (WitnessPaymentKey sk)

mkTxResponse_ :: [SigningKey PaymentKey]-> TxBody AlonzoEra  -> TxResponse
mkTxResponse_ skeys txBody =do
    TxResponse (makeSignedTransaction (map toWitness skeys) txBody ) $  []
  where
    toWitness sk= makeShelleyKeyWitness txBody (WitnessPaymentKey sk)

mkTxResponse' ::ToData a =>  TxContextAddressesReq -> TxBody AlonzoEra -> [a ] -> TxResponse
mkTxResponse' (TxContextAddressesReq mSkey _ _ _ _ _) = mkTxResponse (maybeToList mSkey)

mkTxResponse'' :: TxContextAddressesReq -> TxBody AlonzoEra  -> TxResponse
mkTxResponse'' (TxContextAddressesReq mSkey _ _ _ _ _)  txBody = mkTxResponse (case mSkey of
          Nothing -> []
          Just sk -> [sk])
  where
    mkTxResponse skeys =do
      TxResponse (makeSignedTransaction (map toWitness skeys) txBody ) []
    toWitness sk= makeShelleyKeyWitness txBody (WitnessPaymentKey sk)

mkSignedResponse :: SigningKey PaymentKey -> TxBody AlonzoEra -> TxResponse
mkSignedResponse skey txBody = do
  TxResponse (makeSignedTransaction [makeShelleyKeyWitness txBody (WitnessPaymentKey skey)] txBody) []

unMaybe :: String -> Maybe a -> IO a
unMaybe _ (Just a) = pure a
unMaybe err Nothing = error $ show err

unEither :: Either a b -> IO b
unEither (Right b) = pure b
unEither (Left a) = error $ "Left occured in unEither "

buyToken :: DetailedChainInfo ->  Market -> BuyReqModel -> IO TxResponse
buyToken  networkCtx market
    (BuyReqModel context mSellerDepositSkey mUtxo mAsset consumedData mCollateral) =do
  let conn=getConnectInfo  networkCtx
  let network=getNetworkId networkCtx
  let pParam= case networkCtx of { DetailedChainInfo _ _ param _ _ -> param }
      func add v = calculateTxoutMinLovelace
  minAdaCalc <-case calculateTxoutMinLovelaceFunc pParam of
    Nothing ->  fail "MinUtxo Lovelace calculation failed due to missing protocolParam"
    Just f -> pure  (\add v -> f (TxOut add (TxOutValue MultiAssetInAlonzoEra v) TxOutDatumNone  ) )

  directSale  <- unMaybe "Failed to convert datum to DirectSale"  (fromData $ toPlutusData consumedData)
  TxContextAddresses senderAddress payerAddress changeAddr receiverAddr  paymentAddrMap <-populateAddresses' context network Nothing
  paymentAsset <-unEither $ dsAssetId directSale
  operatorAddr <- unMaybe "Operator  pubKeyHash couldn't be converted to Cardano API address" $  pkhToMaybeAddr network (mTreasury market)
  (txin,txout)<-performQueryScriptUtxo networkCtx ( toAddressAny $ marketAddressShelley market  network)  consumedData mAsset mUtxo "BuyToken"

  -- let ourUtxos=Map.filterWithKey (k -> txin -> Bool) (Map k a)
  let payments=dsPaymentValueList market directSale
  (sellerExtraAmount,extraInputs)<-case mSellerDepositSkey of
    Nothing -> pure ( case selectAsset  (txOutValue txout) paymentAsset of { Quantity n -> n },mempty)
    Just sk -> do
      depositAddrUtxos <- queryUtxosOf networkCtx $ AddressModal $ skeyToAddrInEra  sk network
      pure $ (case selectAsset  (txOutValue txout <> utxoSum depositAddrUtxos) paymentAsset of { Quantity n -> n },
        txConsumeUtxos depositAddrUtxos 
          <> txSignByPkh (sKeyToPkh sk) 
        )

  let mapPartyOperation sellerPkh  (pkh,v)= do
        addr <- case Map.lookup pkh paymentAddrMap of
          Nothing -> pkhToAddr  network pkh
          Just aie -> pure aie
        let val = valueFromList $ [(paymentAsset, Quantity v)]
        pure $ txPayTo addr (ensureMinAda (minAdaCalc addr) val )
  partyPayments <- mapM (mapPartyOperation (dsSeller directSale))  $ dsPaymentValueList market directSale sellerExtraAmount

  let coreOperations = txPayTo operatorAddr (ensureMinAda (minAdaCalc operatorAddr) $ valueFromList [(paymentAsset, Quantity $ dsFee market directSale)])
          <> if receiverAddr == changeAddr
                then mempty
                else txPayTo receiverAddr (ensureMinAda (minAdaCalc receiverAddr ) $ txOutValue txout )

  let txOperations=
          coreOperations
        <> extraInputs
        <> mconcat partyPayments
        <> txRedeemUtxo txin txout (ScriptInAnyLang (PlutusScriptLanguage PlutusScriptV1) (PlutusScript PlutusScriptV1 $ marketScriptSerialised market)) consumedData (fromPlutusData $ PlutusTx.builtinDataToData $ toBuiltinData Buy)
      signatures = maybeToList (txContextAddressesReqSignKey context) ++ maybeToList mSellerDepositSkey

  txbody  <- txBuilderToTxBodyIO networkCtx txOperations
  case txbody of
    Left fe -> throwIO fe
    Right tb -> pure $ mkTxResponse signatures tb [directSale]
  where
    getLedgerBody body = case body of
       ShelleyTxBody era  ledgerBody scripts scriptData maybeAuxData scriptValidity
        -> ledgerBody
    getLedgerBodyScriptData body = case body of
       ShelleyTxBody era  ledgerBody scripts scriptData maybeAuxData scriptValidity
        -> scriptData
    ensureMinAda  f  value =
      if diff > 0
      then value <> lovelaceToValue (Lovelace diff )
      else value
      where
        diff= minLovelace - currentLovelace
        minLovelace= case f $ value <> lovelaceToValue (Lovelace 1_000_000)of {Lovelace n -> n}
        currentLovelace =  case selectAsset value AdaAssetId of {Quantity n -> n}

    hasAsset asset (TxOut _ (TxOutValue _ value) _) = selectAsset value asset >0
    hasAsset _ _ =False
    matchesDatumhash sDataHash (TxOut _ (TxOutValue _ value) (TxOutDatumHash _ hash)) = hash == sDataHash
    matchesDatumhash _ _ =False
    txOutValue (TxOut _ v _) = case v of
      TxOutAdaOnly oasie lo -> lovelaceToValue lo
      TxOutValue masie va -> va

    dsAssetId::DirectSale -> Either FrameworkError AssetId
    dsAssetId DirectSale{dsPaymentCurrency =CurrencySymbol c,dsPaymentTokenName=TokenName t}=
      if BS.null  $ fromBuiltin c
      then Right AdaAssetId
      else
        case  deserialiseFromRawBytes AsPolicyId  (fromBuiltin  c) of
            Just policyId -> case deserialiseFromRawBytes AsAssetName (fromBuiltin t) of
              Just assetName -> Right $ AssetId policyId assetName
              _ -> Left $ FrameworkError ParserError $ "TokenName couldn't be converrted to CardanoAPI type for value : 0x"++   toHexString (fromBuiltin t)
            _ -> Left $ FrameworkError  ParserError $ "Policy Id  couldn't converted to CardanoAPI type  for value : 0x"++ toHexString (fromBuiltin t)
    toBuiltinBs :: ByteString -> BuiltinByteString
    toBuiltinBs  = toBuiltin


marketAddressShelley :: Market -> NetworkId -> Address ShelleyAddr
marketAddressShelley market network = makeShelleyAddress network scriptCredential NoStakeAddress
  where
    scriptCredential=PaymentCredentialByScript marketHash
    marketScript= PlutusScript PlutusScriptV1  $ marketScriptPlutus market
    marketHash= hashScript   marketScript

marketScriptPlutus :: Market -> PlutusScript PlutusScriptV1
marketScriptPlutus market =PlutusScriptSerialised $ marketScriptBS market
  where
    marketScriptBS market = SBS.toShort . LBS.toStrict $ serialise $ marketScript market

marketAddressAny :: ChainInfo v => v -> Market -> AddressAny
marketAddressAny c market= toAddressAny $ marketAddressShelley market  (getNetworkId c)

auctionAddressShelley :: Auction  -> NetworkId -> Address ShelleyAddr
auctionAddressShelley market network = makeShelleyAddress network scriptCredential NoStakeAddress
  where
    scriptCredential=PaymentCredentialByScript marketHash
    marketScript= PlutusScript PlutusScriptV1  $ auctionScriptPlutus market
    marketHash= hashScript   marketScript

auctionScriptPlutus :: Auction -> PlutusScript PlutusScriptV1
auctionScriptPlutus market =PlutusScriptSerialised $ auctionScriptBS market
  where
    auctionScriptBS market = SBS.toShort . LBS.toStrict $ serialise $ auctionScript market

auctionAddressAny :: ChainInfo v => v-> Auction -> AddressAny
auctionAddressAny c market= toAddressAny $ auctionAddressShelley market  (getNetworkId c)

minimizeArataUtxos ::  TVar [(TxIn, TxOut CtxUTxO AlonzoEra)]->  AssetId -> Integer ->  STM ([(TxIn, TxOut CtxUTxO AlonzoEra)],Value)
minimizeArataUtxos val asset amount = do
   v<- readTVar val
   let  (inputs,_)=selectNext v amount
        inputSet= Set.fromList $ map fst inputs
        free = filter (\(a,b) -> a `notElem` inputSet) v
   writeTVar val free
   pure  (inputs,foldMap ( txOutValueToValue . txOutValue . snd) inputs <> valueFromList [(asset, Quantity (- amount))])
  where
    selectNext :: [(TxIn , TxOut CtxUTxO AlonzoEra)] -> Integer -> ([(TxIn,TxOut CtxUTxO AlonzoEra)],Integer)
    selectNext utxos remainingVal = case utxos of
      [] -> ([],remainingVal)
      (txIn,txOut) : subUtxos -> if inThisUtxo >0
          then if diff <= 0
                then ([(txIn,txOut)], diff)
                else case selectNext subUtxos diff of { (tos, tov) -> ((txIn,txOut):tos, tov) }
          else
            selectNext subUtxos diff
        where
            inThisUtxo= txOutValueToAmount $ txOutValue txOut
            diff = remainingVal-inThisUtxo

    txOutValue (TxOut _ v _) = v
    txOutValueToValue :: TxOutValue era -> Value
    txOutValueToValue tv =
      case tv of
        TxOutAdaOnly _ l -> lovelaceToValue  l
        TxOutValue _ v -> v
    txOutValueToAmount :: TxOutValue era -> Integer
    txOutValueToAmount tv =
      case tv of
        TxOutAdaOnly _ l -> 0
        TxOutValue _ v -> case selectAsset v asset of { Quantity n -> n }
    valueContentInt v = case selectAsset v asset of { Quantity n -> n }

minimizeChange :: UTxO AlonzoEra  -> Value -> ([(TxIn, TxOut CtxUTxO AlonzoEra )], Value)
minimizeChange (UTxO utxos)  val =minimize (Map.toList utxos) (totalInput <> val)
  where
    minimize utxos remainingChange= case utxos of
      []     -> ([] ,remainingChange)
      (txIn,txOut):subUtxos -> if val `valueLte` remainingChange
              then minimize subUtxos newChange -- remove the current txOut from the list
              else (case minimize subUtxos remainingChange of { (tos, va) -> ((txIn,txOut) :tos,va) }) -- include txOut in result
            where
              val = txOutValueToValue $ txOutValue  txOut
              newChange= remainingChange <> negateValue val

    txOutValue (TxOut _ v _) = v
    txOutValueToValue :: TxOutValue era -> Value
    txOutValueToValue tv =
      case tv of
        TxOutAdaOnly _ l -> lovelaceToValue l
        TxOutValue _ v -> v
    totalInput = foldMap (txOutValueToValue . txOutValue) (Map.elems utxos)

performQueryScriptUtxo :: ChainInfo v => v ->  AddressAny  ->  ScriptData -> Maybe AssetId -> Maybe UtxoIdModal-> String -> IO  (TxIn ,TxOut CtxUTxO AlonzoEra)
performQueryScriptUtxo  ctx  addr  sData maybeAsset maybeUtxo queryContextPrefix = do
  q <- queryScriptUtxo ctx addr sData maybeAsset (maybeUtxo <&> unUtxoIdModal )
  case q of
    Left s -> fail $ queryContextPrefix ++ " : " ++ s
    Right x0 -> pure x0

queryScriptUtxo :: ChainInfo v => v -> AddressAny  ->  ScriptData -> Maybe AssetId -> Maybe (TxId,TxIx)  -> IO (Either String (TxIn ,TxOut CtxUTxO AlonzoEra))
queryScriptUtxo  ctx  addr  sData maybeAsset maybeUtxo  = do
  UTxO uMap <- queryUtxos (getConnectInfo ctx)  (Set.singleton addr) >>= unEitherIO
  pure $ case maybeUtxo of
    Nothing ->  do
      let v = Map.filter (filterWithSdata sData) uMap
      if Map.size v ==0
        then   returnError $ "No Utxo found on address " ++  T.unpack ( serialiseAddress addr) ++ " with dataHash :"++ show (hashScriptData sData )
        else  (case maybeAsset of
        Nothing ->   pure $ head $ Map.toList v
        Just aid -> do
          let v'=Map.filter (filterWithAsset aid) v
          if Map.null v'
            then  returnError "Utxo with data Hash found but it doesn't contain the asset"
            else  pure $ head $ Map.toList v'
          )

    Just (_id,index) ->
      let _in=TxIn _id index
      in case Map.lookup  _in uMap of
        Nothing ->  returnError $  "Utxo not found : " ++ show _id ++ "#" ++ show index
        Just to -> case to of
          TxOut aie tov (TxOutDatumHash _ hash) -> if hash == hashScriptData sData
              then pure (_in, to)
              else returnError $  "Utxo DataHash mismatch. expecting : "++ show (hashScriptData sData) ++ "got " ++show hash
          _  ->   returnError "Utxo Is Not Script Utxo or Data Hash is missing in it"
  where
    returnError m = Left m
    filterWithAsset ::AssetId   ->  TxOut CtxUTxO AlonzoEra -> Bool
    filterWithAsset  aid (TxOut _ (TxOutValue _ val) _ )= selectAsset val aid > 0
    filterWithAsset  _ _ = False

    filterWithSdata ::ScriptData ->  TxOut CtxUTxO AlonzoEra -> Bool
    filterWithSdata  sdata (TxOut _ _ (TxOutDatumHash _ dataHash))= hashScriptData sdata == dataHash
    filterWithSdata  _ _ = False

unEitherIO :: Either FrameworkError a -> IO a
unEitherIO (Left s) = error $ show s
unEitherIO (Right x) = pure x

queryScriptUtxoByAsset :: ChainInfo v => v  ->  AddressAny  ->  ScriptData -> Maybe (TxId,TxIx) -> String -> IO (TxIn ,TxOut CtxUTxO AlonzoEra)
queryScriptUtxoByAsset  ctx  addr  sData maybeUtxo queryContextPrefix= do
  UTxO uMap <- queryUtxos (getConnectInfo ctx)  (Set.singleton addr) >>= unEitherIO
  case maybeUtxo of
    Nothing -> do
      let v = Map.filter (filterWithSdata sData) uMap
      if Map.size v ==0
        then fail $ queryContextPrefix ++ "No Utxo found with dataHash :"++ show (hashScriptData sData )
        else  pure $ head $ Map.toList v
    Just (_id,index) ->
      let _in=TxIn _id index
      in case Map.lookup  _in uMap of
        Nothing -> fail $ queryContextPrefix ++ "Utxo not found : " ++ show _id ++ "#" ++ show index
        Just to -> case to of
          TxOut aie tov (TxOutDatumHash _ hash) -> if hash == hashScriptData sData
              then pure (_in, to)
              else fail $ queryContextPrefix ++ "Utxo DataHash mismatch expecting : "++ show (hashScriptData sData) ++ "got " ++show hash
          _  ->  fail $ queryContextPrefix ++ "Utxo Is Not Script Utxo or Data Hash is missing in it"
  where
    filterWithTxId:: TxIn -> TxIn -> TxOut CtxUTxO AlonzoEra -> Bool
    filterWithTxId base compare _= base == compare

    filterWithSdata ::ScriptData ->  TxOut CtxUTxO AlonzoEra -> Bool
    filterWithSdata  sdata (TxOut _ _ (TxOutDatumHash _ dataHash))= hashScriptData sdata == dataHash
    filterWithSdata  _ _ = False


auctionAssetId::Auction -> Either FrameworkError AssetId
auctionAssetId Auction{ aAssetClass= AssetClass(CurrencySymbol c, TokenName t)}=
  if BS.null  $ fromBuiltin c
  then Right AdaAssetId
  else
    case  deserialiseFromRawBytes AsPolicyId  (fromBuiltin  c) of
        Just policyId -> case deserialiseFromRawBytes AsAssetName (fromBuiltin t) of
          Just assetName -> Right $ AssetId policyId assetName
          _ -> Left $ FrameworkError ParserError $ "TokenName couldn't be converrted to CardanoAPI type for value : 0x"++   toHexString (fromBuiltin t)
        _ -> Left $ FrameworkError ParserError $ "Policy Id  couldn't converted to CardanoAPI type  for value : 0x"++ toHexString (fromBuiltin t)

fromPlutusValue :: PlutusValue.Value -> Value
fromPlutusValue (PlutusValue.Value map) = valueFromList $  concatMap toAssetIdQuantityList $ AssocMap.toList map
  where
    toAssetIdQuantityList (currency,assetMap) = mapMaybe  (toAssetIdQuantityPair currency)  $ AssocMap.toList assetMap
    toAssetIdQuantityPair (CurrencySymbol c) (TokenName t , q) =
        if BS.null  $ fromBuiltin c
        then Just (AdaAssetId,Quantity q)
        else
          case  deserialiseFromRawBytes AsPolicyId  (fromBuiltin  c) of
              Just policyId -> case deserialiseFromRawBytes AsAssetName (fromBuiltin t) of
                Just assetName -> Just  (AssetId policyId assetName, Quantity q)
                _ -> Nothing
              _ -> Nothing
fromPlutusAssetClass :: AssetClass -> AssetId
fromPlutusAssetClass (AssetClass (CurrencySymbol c, TokenName t)) =
  if BS.null  $ fromBuiltin c
    then AdaAssetId
    else
      case  deserialiseFromRawBytes AsPolicyId  (fromBuiltin  c) of
          Just policyId -> case deserialiseFromRawBytes AsAssetName (fromBuiltin t) of
            Just assetName -> AssetId policyId assetName
            _ -> error "Failed co convert Assetname to CardanoApi"
          _ -> error "Failed to convert policyId to cardanoApi"

datumString :: ScriptData -> String
datumString _data = toHexString $  encode $ scriptDataToJson ScriptDataJsonDetailedSchema   _data

dataumStringJson :: ScriptData -> String
dataumStringJson  _data = BSChar8.unpack $ encode $ scriptDataToJson ScriptDataJsonDetailedSchema   _data

-- TODO
-- txOperatorActions :: RuntimeContext -> IO TxBuilder
-- txOperatorActions  rCtx = do
--   pure $ txAddSignature (runtimeContextOperatorSkey rCtx)
--   where
--   isOnlyAdaTxOut (TxOut a v d) = case v of
--       -- only ada then it's ok
--       TxOutAdaOnly oasie lo -> True
--       -- make sure that it has only one asset and that one is ada asset.
--       TxOutValue masie va -> length vals == 1 && snd(head vals) > 0
--             where
--               vals=valueToList  va

  -- toVal (TxOut _ (TxOutValue _ v) _) = v
  -- toVal (TxOut _ (TxOutAdaOnly _ l) _) = lovelaceToValue l