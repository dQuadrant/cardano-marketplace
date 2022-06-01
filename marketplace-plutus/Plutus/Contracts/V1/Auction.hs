{-# LANGUAGE NoImplicitPrelude  #-}
{-# OPTIONS_GHC -fno-ignore-interface-pragmas #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE NumericUnderscores#-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE TemplateHaskell #-}
module Plutus.Contracts.V1.Auction
where

-- import GHC.Generics (Generic)
import PlutusTx.Prelude
-- import qualified Prelude
-- import PlutusTx ( FromData(..),makeIsDataIndexed ,makeLift,compile,liftCode,applyCode)
-- import Plutus.V1.Ledger.Api
-- import Plutus.V1.Ledger.Value ( assetClassValue, geq, AssetClass (AssetClass),singleton,assetClassValueOf )
-- import Plutus.V1.Ledger.Contexts (valuePaidTo, ownHash, valueLockedBy, findOwnInput, findDatum,txSignedBy,getContinuingOutputs,txSignedBy)
-- import Plutus.V1.Ledger.Address (toPubKeyHash, scriptHashAddress, toValidatorHash)
-- import Plutus.V1.Ledger.Scripts (getScriptHash, ScriptHash (ScriptHash))
-- import Plutus.V1.Ledger.Interval(contains,after,before,Extended(..))
-- import qualified PlutusTx.AssocMap as AssocMap
-- import Data.Aeson (FromJSON, ToJSON)
-- import qualified Data.Bifunctor
-- import Prelude (Show)
-- import qualified Data.ByteString.Short as SBS
-- import qualified Data.ByteString.Lazy  as LBS
-- import Cardano.Api.Shelley (PlutusScript (..), PlutusScriptV1)
-- import Codec.Serialise


-- ---------------------------------------------------------------------------------------------
-- ----- Foreign functions (these used be in some other file but PLC plugin didn't agree)
-- ---------------------------------------------------------------------------------------------

-- -- Payment.hs
-- newtype Payment = Payment ( AssocMap.Map PubKeyHash Value ) deriving(Generic,ToJSON,FromJSON)

-- instance Semigroup Payment where
--     {-# INLINABLE (<>) #-}
--     (<>) (Payment a) (Payment b) = Payment (a <> b)

-- instance Monoid Payment where
--   {-# INLINABLE mempty   #-}
--   mempty = Payment AssocMap.empty


-- {-# INLINABLE payment  #-}
-- payment :: PubKeyHash -> Value -> Payment
-- payment pkHash value=Payment  (AssocMap.singleton pkHash value)

-- {-# INLINABLE assetClassPayment #-}
-- assetClassPayment :: AssetClass  -> [(PubKeyHash,Integer)] -> Payment
-- assetClassPayment ac values=Payment (AssocMap.fromList mappedList)
--   where
--     mappedList= map (Data.Bifunctor.second (assetClassValue ac)) values

-- {-# INLINABLE paymentValue #-}
-- paymentValue :: Payment -> PubKeyHash -> Value
-- paymentValue (Payment p) pkh=case AssocMap.lookup pkh p of
--     Just v ->  v
--     _      ->Value AssocMap.empty

-- {-# INLINABLE paymentPkhs #-}
-- paymentPkhs :: Payment -> [PubKeyHash]
-- paymentPkhs (Payment x) =  AssocMap.keys x

-- -- moving this function to Data/Payment.hs will give following error
-- --
-- --GHC Core to PLC plugin: E043:Error: Reference to a name which is not a local, a builtin, or an external INLINABLE function:
-- -- Variable Plutus.Contract.Data.Payment.$s$fFoldable[]_$cfoldMap
-- --            OtherCon 
-- --Context: Compiling expr: Plutus.Contract.Data.Payment.$s$fFoldable[]_$cfoldMap

-- {-# INLINABLE validatePayment #-}
-- validatePayment :: (PubKeyHash ->  Value -> Bool )-> Payment ->Bool
-- validatePayment f p=
--  all  (\pkh -> f pkh (paymentValue p pkh)) (paymentPkhs p)



-- -- moving this function to Blockchain/Utils.hs will give following error
-- --
-- --GHC Core to PLC plugin: E043:Error: Reference to a name which is not a local, a builtin,
-- --  or an external INLINABLE function: Variable
-- --  Plutus.Contract.Blockchain.Utils.$s$fFoldable[]_$cfoldMap
-- --           No unfolding


-- --Utils.hs
-- -- address of this validator
-- {-# INLINABLE ownAddress #-}
-- ownAddress :: ScriptContext -> Address
-- ownAddress ctx=scriptHashAddress (ownHash ctx)

-- -- all the utxos that are being redeemed from this contract in this transaction
-- {-# INLINABLE  ownInputs #-}
-- ownInputs:: ScriptContext -> [TxOut]
-- ownInputs ctx@ScriptContext{scriptContextTxInfo=TxInfo{txInfoInputs}}=
--      filter (\x->txOutAddress x==ownAddress ctx) resolved
--     where
--     resolved=map (\x->txInInfoResolved x) txInfoInputs

-- -- get List of valid parsed datums  the script in this transaction
-- {-# INLINABLE ownInputDatums #-}
-- ownInputDatums :: FromData a => ScriptContext  -> [a]
-- ownInputDatums ctx= mapMaybe (txOutDatum ctx) $  ownInputs ctx

-- -- get List of the parsed datums  including the TxOut if datum is valid
-- {-# INLINABLE ownInputsWithDatum #-}
-- maybeOwnInputsWithDatum:: FromData a =>  ScriptContext ->[Maybe (TxOut,a)]
-- maybeOwnInputsWithDatum ctx=map (txOutWithDatum ctx)  ( ownInputs ctx)

-- ownInputsWithDatum:: FromData a=> ScriptContext  -> [(TxOut,a)]
-- ownInputsWithDatum ctx= map doValidate (ownInputs ctx)
--   where
--     doValidate:: FromData a =>  TxOut -> (TxOut,a)
--     doValidate txOut = case txOutWithDatum ctx txOut of
--       Just a -> a
--       _      -> traceError "Datum format in Utxo is not of required type"

-- -- get input datum for the utxo that is currently being validated
-- {-# INLINABLE ownInputDatum #-}
-- ownInputDatum :: FromData a => ScriptContext -> Maybe a
-- ownInputDatum ctx = do
--     txInfo <-findOwnInput ctx
--     let txOut= txInInfoResolved txInfo
--     txOutDatum ctx txOut

-- --  given an Utxo, resolve it's datum to our type
-- {-# INLINABLE txOutDatum #-}
-- txOutDatum::  FromData a =>  ScriptContext ->TxOut -> Maybe a
-- txOutDatum ctx txOut =do
--             dHash<-txOutDatumHash txOut
--             datum<-findDatum dHash (scriptContextTxInfo ctx)
--             PlutusTx.fromBuiltinData $ getDatum datum

-- -- given txOut get resolve it to our type and return it with the txout
-- {-# INLINABLE txOutWithDatum #-}
-- txOutWithDatum::  FromData a =>  ScriptContext ->TxOut -> Maybe (TxOut,a)
-- txOutWithDatum ctx txOut =do
--             d<-txOutDatum ctx txOut
--             return (txOut,d)

-- --  value that is being redeemed from this contract in this utxo
-- {-# INLINABLE ownInputValue #-}
-- ownInputValue:: ScriptContext -> Value
-- ownInputValue ctx = case  findOwnInput ctx of
--       Just TxInInfo{txInInfoResolved} ->  txOutValue txInInfoResolved

-- -- total value that will be locked by this contract in this transaction
-- {-# INLINABLE  ownOutputValue #-}
-- ownOutputValue :: ScriptContext -> Value
-- ownOutputValue ctx = valueLockedBy (scriptContextTxInfo ctx) (ownHash ctx)


-- {-# INLINABLE allowSingleScript #-}
-- allowSingleScript:: ScriptContext  -> Bool
-- allowSingleScript ctx@ScriptContext{scriptContextTxInfo=TxInfo{txInfoInputs}} =
--     all checkScript txInfoInputs
--   where
--     checkScript (TxInInfo _ (TxOut address _ _))=
--       case addressCredential  address of
--         ScriptCredential vhash ->  traceIfFalse  "Reeming other Script utxo is Not allowed" (thisScriptHash == vhash)
--         _ -> True
--     thisScriptHash= ownHash ctx


-- allScriptInputsCount:: ScriptContext ->Integer
-- allScriptInputsCount ctx@(ScriptContext info purpose)=
--     foldl (\c txOutTx-> c + countTxOut txOutTx) 0 (txInfoInputs  info)
--   where
--   countTxOut (TxInInfo _ (TxOut addr _ _)) = if isJust (toValidatorHash addr) then 1 else 0

-- ----------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------

{-# INLINABLE auctionHundredPercent #-}
auctionHundredPercent :: Percent
auctionHundredPercent=100_000_000

-- percent:: Integer -> Percent
-- percent a = a * 1_000_000


-- newtype Price = Price (CurrencySymbol ,TokenName ,Integer) deriving(Generic,ToJSON,FromJSON)
type Percent = Integer

-- {-# INLINABLE valueOfPrice #-}
-- valueOfPrice :: Price ->  Value
-- valueOfPrice (Price (c,t,v)) = singleton c t v


-- data AuctionRedeemer =  ClaimBid| Bid | Withdraw
--     deriving (Generic,FromJSON,ToJSON,Prelude.Eq)

-- data Auction = Auction{
--     aOperator           :: !PubKeyHash,
--     aTreasuryAddress    :: !PubKeyHash,
--     aPlatformFee        :: !Integer,
--     aOwner  :: !PubKeyHash, -- pkh Who created the auction.
--     aSplits :: [(PubKeyHash,Percent)],
--     aAssetClass:: !AssetClass, -- The Bidding currency for auction.
--     aMinBid :: !Integer, -- starting Bid
--     aMinIncrement :: !Integer, -- min increment  from previous auction per bid
--     aDuration:: !(Maybe POSIXTimeRange), -- Auction duration
--     aValue:: !Value  -- The value that's placed on Auction. this is what winner gets.
-- } deriving (Generic,Show, ToJSON,FromJSON)

-- -- Given final bid value
-- -- Calculate Value to be payed to all the seller parties of auction
-- -- Note that sellerReceiving = totalBid - AuctionConfigFee - otherPartyPayment - buyer's Payment
-- {-# INLINABLE aPaymentReceiversValue #-}
-- aPaymentReceiversValue ::  Auction -> Value-> [(PubKeyHash,Value)]
-- aPaymentReceiversValue a@Auction{aOwner,aAssetClass,aValue,aPlatformFee} closingValue =
--     aOwnerPart : partiesPart
--   where
--     aOwnerPart=(aOwner,closingValue -aValue- afeeValue-assetClassValue aAssetClass (sum $ map snd partiesPayment) )
--     partiesPart = map (\(pkh,v)-> (pkh,assetClassValue aAssetClass v)) partiesPayment
--     partiesPayment=map (\(pkh,v) ->(pkh,(v*totalPayment)`divide` auctionHundredPercent)) (aSplits a)
--     totalPayment = aPaymentAfterFee a closingValue
--     afeeValue= auctionAssetValue a $ aFee  a closingValue

-- -- Given final bid value in an auction,
-- --  Create pament map for the auction seller parties
-- {-# INLINABLE aPaymentRecivers #-}
-- aPaymentRecivers:: Auction->Value->Payment
-- aPaymentRecivers a@Auction{aAssetClass,aValue,aSplits,aPlatformFee} fValue=
--   foldMap toPayment (aPaymentReceiversValue a fValue)
--   where
--     toPayment (pkh,v) = payment pkh v

-- -- Given final bid value in an auction,
-- -- Get the amount after deducting Auctionfee. It is to be distributed among seller parties.
-- {-# INLINABLE aPaymentAfterFee #-}
-- aPaymentAfterFee ::Auction -> Value -> Integer
-- aPaymentAfterFee  a@Auction{aPlatformFee,aAssetClass} v =totalPayment
--   where
--     totalPayment= ((auctionHundredPercent-aPlatformFee ) * totalClosingValue) `divide` auctionHundredPercent
--     totalClosingValue = assetClassValueOf v aAssetClass


-- -- Given final bid, get Auction fee to be paid when claiming auction
-- {-# INLINABLE aFee #-}
-- aFee ::  Auction -> Value-> Integer
-- aFee Auction{aAssetClass,aPlatformFee} fValue = finalAssetValue - sellerValue
--     where
--       sellerValue=(sellerPercent * finalAssetValue) `divide` auctionHundredPercent
--       sellerPercent=auctionHundredPercent-aPlatformFee
--       finalAssetValue= assetClassValueOf fValue aAssetClass

-- -- the interval object representime the time by which auction can be claimed
-- aClaimInterval :: Auction-> Interval POSIXTime
-- aClaimInterval Auction{aDuration}= case aDuration of 
--   Just _duration -> Interval (toLower $ ivTo _duration) (UpperBound PosInf False)
--               where
--                 toLower (UpperBound  a _)=LowerBound a True
--   Nothing -> Interval (LowerBound NegInf True) (UpperBound NegInf True)

-- -- Given a payment get It as value of Auction's asset class
-- {-# INLINABLE auctionAssetValue #-}
-- auctionAssetValue :: Auction -> Integer -> Value
-- auctionAssetValue Auction{aAssetClass=AssetClass (c, t)} = singleton c t


-- {-# INLINABLE  validateBid #-}
-- validateBid :: Auction ->  PubKeyHash -> ScriptContext -> Bool
-- validateBid auction@Auction{aAssetClass, aOwner,aValue} bidder ctx@ScriptContext  {scriptContextTxInfo=info}=
--       traceIfFalse "Only one bid per transaction" (allScriptInputsCount  ctx ==1 )
--       &&  traceIfFalse "The asset is not present in the auction utxo" validInputDatum
--       &&  traceIfFalse "Insufficient payment to the contract" isAuctionScriptPayed
--       &&  traceIfFalse "Insufficient payment to previous bidder" isExBidderPaid
--        &&  duringTheValidity
--   where
--     duringTheValidity  =   case aDuration auction of  
--           Just  _duration -> traceIfFalse "Not  the auction period" $ _duration `contains` txInfoValidRange info
--           _               -> True
--     -- without this check, auction creator might say that
--     -- they are placing asset on auction datum without locking them.
--     validInputDatum = ownInputValue ctx `geq` aValue 
--     minNewBid = if  bidder == aOwner
--                     then aMinBid auction
--                     else aMinIncrement auction + lastAuctionAssetValue
    
--     isExBidderPaid= assetClassValueOf  (valuePaidTo info bidder)  aAssetClass
--                         >= lastAuctionAssetValue

--     lastAuctionAssetValue= assetClassValueOf  (ownInputValue ctx ) aAssetClass

--     isAuctionScriptPayed = ownOutputValue ctx `geq` 
--             (    ownInputValue ctx 
--               <> assetClassValue  aAssetClass ( minNewBid - lastAuctionAssetValue)
--             )

--     newTxOut=case getContinuingOutputs ctx of
--        [txOut] -> txOut
--        _       -> traceError "MultipleOutputs"


-- {-# INLINABLE  validateWithdraw #-}
-- validateWithdraw ::  Auction  ->  PubKeyHash -> ScriptContext -> Bool
-- validateWithdraw auction@Auction{aOwner,aOperator} bidder ctx=
--       traceIfFalse "Auction has bids" (bidder==aOwner)
--   &&  traceIfFalse "Missing signatures" ( txSignedBy  info aOwner || (txSignedBy info aOperator && isOwnerPaid) )
--   where
--     isOwnerPaid= valuePaidTo  info aOwner  `geq` (ownInputValue ctx <> negate  (txInfoFee info))
--     info  =  scriptContextTxInfo ctx

-- {-# INLINABLE validateClaimAuction  #-}
-- validateClaimAuction :: Auction  -> ScriptContext -> Bool
-- validateClaimAuction  auction@Auction{aPlatformFee,aOperator,aTreasuryAddress,aOwner} ctx@ScriptContext{scriptContextTxInfo=info} =
--           allowSingleScript ctx
--      &&  traceIfFalse "Operator not paid" isOperatorPaid
--      &&  traceIfFalse "Bidder not paid"     isWinnerPayed
--      && traceIfFalse  "Sellers not paid"      areSellersPaid
--      && isAuctionExpired 
--       where

--         -- Check that each of the parties are paid
--         isWinnerPayed  = valuePaidTo info bidder  `geq` (aValue auction <> negate (txInfoFee info))
--         areSellersPaid  = validatePayment (\pkh v -> valuePaidTo info pkh  `geq` v)  totalSellerPayment
--         isOperatorPaid  = valuePaidTo info aTreasuryAddress `geq`  totalOperatorFee

--         -- Total payments arising from the utxos
--         totalSellerPayment =  aPaymentRecivers  auction  (txOutValue txOut)
--         totalOperatorFee   =  auctionAssetValue auction $ aFee auction $ txOutValue txOut

--         txOut = fst bidderWithTxOut
--         bidder = snd bidderWithTxOut

--         bidderWithTxOut:: (TxOut,PubKeyHash)
--         bidderWithTxOut=case ownInputsWithDatum  ctx of
--           [v] -> v
--           _ -> traceError "Too many script inputs"
        
--         isAuctionExpired = case aDuration auction of 
--           Just _duration ->traceIfFalse  "Auction not Expired" $  case (case  ivFrom (txInfoValidRange info) of { LowerBound (v ) _ -> v}) of 
--                 NegInf   -> case ivTo _duration of  
--                   UpperBound NegInf _  -> hasSignatures
--                   UpperBound PosInf _  -> hasSignatures
--                   _                    -> False
--                 Finite a -> a `after` _duration
--                 PosInf   -> hasSignatures 
--           Nothing   -> hasSignatures
--           where
--               hasSignatures= any (\x -> x== aOwner || x==aOperator) (txInfoSignatories info)

        
-- {-# INLINABLE mkAuction #-}
-- mkAuction :: Auction    ->  PubKeyHash -> AuctionRedeemer -> ScriptContext  -> Bool
-- mkAuction  auction  lastBidder action ctx =
--     case  action of
--         Withdraw  -> validateWithdraw  auction lastBidder ctx
--         Bid       -> validateBid auction lastBidder ctx
--         ClaimBid  -> validateClaimAuction auction ctx



-- PlutusTx.makeIsDataIndexed ''AuctionRedeemer [('ClaimBid, 0), ('Bid, 1),('Withdraw,2)]

-- PlutusTx.makeLift ''Auction
-- PlutusTx.makeIsDataIndexed ''Auction [('Auction, 0)]

-- {-# INLINABLE mkWrappedAuction #-}
-- mkWrappedAuction :: Auction -> BuiltinData -> BuiltinData -> BuiltinData -> ()
-- mkWrappedAuction  m d r c = check $ mkAuction m (unsafeFromBuiltinData d) (unsafeFromBuiltinData r) (unsafeFromBuiltinData c)

-- auctionValidator :: Auction -> Validator
-- auctionValidator auction = mkValidatorScript  $
--             $$(PlutusTx.compile [|| mkWrappedAuction ||])
--             `applyCode` PlutusTx.liftCode auction

-- auctionScript :: Auction -> Script
-- auctionScript auction =  unValidatorScript  (auctionValidator auction)

-- auctionScriptSBS :: Auction -> SBS.ShortByteString
-- auctionScriptSBS auction =  SBS.toShort . LBS.toStrict $ serialise $ auctionScript auction

-- auctionScriptSerialised :: Auction -> PlutusScript PlutusScriptV1
-- auctionScriptSerialised auction = PlutusScriptSerialised $ auctionScriptSBS auction

