{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE EmptyDataDecls #-}
{-# LANGUAGE NoImplicitPrelude  #-}
{-# LANGUAGE TemplateHaskell    #-}
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
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE AllowAmbiguousTypes #-}
module Plutus.Contracts.V1.MarketPlace
where

import GHC.Generics (Generic)
import PlutusTx.Prelude
import Prelude(Show)
import qualified Prelude
import  PlutusTx hiding( txOutDatum)
import Data.Aeson (FromJSON, ToJSON)
import qualified PlutusTx.AssocMap as AssocMap
import qualified Data.Bifunctor
import Plutus.V1.Ledger.Api
import Plutus.V1.Ledger.Value ( assetClassValue, geq, AssetClass(..),CurrencySymbol(..),TokenName(..), assetClassValueOf )
import Plutus.V1.Ledger.Contexts (valuePaidTo, ownHash, valueLockedBy, findOwnInput, findDatum,txSignedBy)
import Plutus.V1.Ledger.Address (toPubKeyHash, scriptHashAddress, toValidatorHash)
import Plutus.V1.Ledger.Scripts (getScriptHash, ScriptHash (ScriptHash))


---------------------------------------------------------------------------------------------
----- Foreign functions 
---------------------------------------------------------------------------------------------

-- Payment.hs
newtype Payment = Payment ( AssocMap.Map PubKeyHash Value ) deriving(Generic,ToJSON,FromJSON)
instance Semigroup Payment where
    {-# INLINABLE (<>) #-}
    (<>) (Payment a) (Payment b) = Payment (a <> b)

instance Monoid Payment where
  {-# INLINABLE mempty   #-}
  mempty = Payment AssocMap.empty


{-# INLINABLE payment  #-}
payment :: PubKeyHash -> Value -> Payment
payment pkHash value=Payment  (AssocMap.singleton pkHash value)

{-# INLINABLE assetClassPayment #-}
assetClassPayment :: AssetClass  -> [(PubKeyHash,Integer)] -> Payment
assetClassPayment ac values=Payment (AssocMap.fromList mappedList)
  where
    mappedList= map (Data.Bifunctor.second (assetClassValue ac)) values

{-# INLINABLE paymentValue #-}
paymentValue :: Payment -> PubKeyHash -> Value
paymentValue (Payment p) pkh=case AssocMap.lookup pkh p of
    Just v ->  v
    _      ->Value AssocMap.empty

{-# INLINABLE paymentPkhs #-}
paymentPkhs :: Payment -> [PubKeyHash]
paymentPkhs (Payment x) =  AssocMap.keys x

-- moving this function to Data/Payment.hs will give following error
--
--GHC Core to PLC plugin: E043:Error: Reference to a name which is not a local, a builtin, or an external INLINABLE function:
-- Variable Plutus.Contract.Data.Payment.$s$fFoldable[]_$cfoldMap
--            OtherCon []
--Context: Compiling expr: Plutus.Contract.Data.Payment.$s$fFoldable[]_$cfoldMap

{-# INLINABLE validatePayment#-}
validatePayment :: (PubKeyHash ->  Value -> Bool )-> Payment ->Bool
validatePayment f p=
 all  (\pkh -> f pkh (paymentValue p pkh)) (paymentPkhs p)


--Utils.hs
-- address of this validator
{-# INLINABLE ownAddress #-}
ownAddress :: ScriptContext -> Address
ownAddress ctx=scriptHashAddress (ownHash ctx)

-- all the utxos that are being redeemed from this contract in this transaction
{-# INLINABLE  ownInputs #-}
ownInputs:: ScriptContext -> [TxOut]
ownInputs ctx@ScriptContext{scriptContextTxInfo=TxInfo{txInfoInputs}}=
     filter (\x->txOutAddress x==ownAddress ctx) resolved
    where
    resolved=map (\x->txInInfoResolved x) txInfoInputs

-- get List of valid parsed datums  the script in this transaction
{-# INLINABLE ownInputDatums #-}
ownInputDatums :: FromData a => ScriptContext  -> [a]
ownInputDatums ctx= mapMaybe (txOutDatum ctx) $  ownInputs ctx

-- get List of the parsed datums  including the TxOut if datum is valid
{-# INLINABLE ownInputsWithDatum #-}
maybeOwnInputsWithDatum:: FromData a =>  ScriptContext ->[Maybe (TxOut,a)]
maybeOwnInputsWithDatum ctx=map (txOutWithDatum ctx)  ( ownInputs ctx)

ownInputsWithDatum:: FromData a=> ScriptContext  -> [(TxOut,a)]
ownInputsWithDatum ctx= map doValidate (ownInputs ctx)
  where
    doValidate:: FromData a =>  TxOut -> (TxOut,a)
    doValidate txOut = case txOutWithDatum ctx txOut of
      Just a -> a
      _      -> traceError "Datum format in Utxo is not of required type"

-- get input datum for the utxo that is currently being validated
{-# INLINABLE ownInputDatum #-}
ownInputDatum :: FromData a => ScriptContext -> Maybe a
ownInputDatum ctx = do
    txInfo <-findOwnInput ctx
    let txOut= txInInfoResolved txInfo
    txOutDatum ctx txOut

--  given an Utxo, resolve it's datum to our type
{-# INLINABLE txOutDatum #-}
txOutDatum::  FromData a =>  ScriptContext ->TxOut -> Maybe a
txOutDatum ctx txOut =do
            dHash<-txOutDatumHash txOut
            datum<-findDatum dHash (scriptContextTxInfo ctx)
            PlutusTx.fromBuiltinData $ getDatum datum

-- given txOut get resolve it to our type and return it with the txout
{-# INLINABLE txOutWithDatum #-}
txOutWithDatum::  FromData a =>  ScriptContext ->TxOut -> Maybe (TxOut,a)
txOutWithDatum ctx txOut =do
            d<-txOutDatum ctx txOut
            return (txOut,d)

--  value that is being redeemed from this contract in this utxo
{-# INLINABLE ownInputValue #-}
ownInputValue:: ScriptContext -> Value
ownInputValue ctx = case  findOwnInput ctx of
      Just TxInInfo{txInInfoResolved} ->  txOutValue txInInfoResolved

-- total value that will be locked by this contract in this transaction
{-# INLINABLE  ownOutputValue #-}
ownOutputValue :: ScriptContext -> Value
ownOutputValue ctx = valueLockedBy (scriptContextTxInfo ctx) (ownHash ctx)


{-# INLINABLE allowSingleScript #-}
allowSingleScript:: ScriptContext  -> Bool
allowSingleScript ctx@ScriptContext{scriptContextTxInfo=TxInfo{txInfoInputs}} =
    all checkScript txInfoInputs
  where
    checkScript (TxInInfo _ (TxOut address _ _))=
      case addressCredential  address of
        ScriptCredential vhash ->  traceIfFalse  "Reeming other Script utxo is Not allowed" (thisScriptHash == vhash)
        _ -> True
    thisScriptHash= ownHash ctx


allScriptInputsCount:: ScriptContext ->Integer
allScriptInputsCount ctx@(ScriptContext info purpose)=
    foldl (\c txOutTx-> c + countTxOut txOutTx) 0 (txInfoInputs  info)
  where
  countTxOut (TxInInfo _ (TxOut addr _ _)) = if isJust (toValidatorHash addr) then 1 else 0


----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

{-# INLINABLE marketHundredPercent #-}
marketHundredPercent :: Percent
marketHundredPercent=100_000_000

percent:: Integer -> Percent
percent a = a * 1_000_000


newtype Price = Price (CurrencySymbol ,TokenName ,Integer) deriving(Show,Generic,ToJSON,FromJSON)
type Percent = Integer

{-# INLINABLE valueOfPrice#-}
valueOfPrice :: Price ->  Value
valueOfPrice (Price (c,t,v)) = singleton c t v


data Market = Market
    {   mTreasury           :: !PubKeyHash
    ,   mOperator           :: !PubKeyHash
    ,   mPrimarySaleFee     :: !Integer
    ,   mSecondarySaleFee   :: !Integer
    } deriving (Show,Generic, FromJSON, ToJSON)

PlutusTx.makeLift ''Market

data MarketRedeemer =  Buy | Withdraw
    deriving (Generic,FromJSON,ToJSON,Show,Prelude.Eq)
PlutusTx.makeIsDataIndexed ''MarketRedeemer [('Buy, 0), ('Withdraw, 1)]

data SellType = Primary | Secondary  deriving (Show,Generic,ToJSON,FromJSON,Prelude.Eq)
PlutusTx.makeIsDataIndexed ''SellType [('Primary, 0), ('Secondary, 1)]

type PartyShare=(PubKeyHash,Percent)

data DirectSale=DirectSale{
    dsSeller:: PubKeyHash, -- The main seller
    dsSplits::  [(PubKeyHash,Percent)], -- Percentage payment for other parties of sale.
    dsPaymentCurrency :: CurrencySymbol ,
    dsPaymentTokenName:: TokenName  ,
    dsCost:: Integer,  -- ^ total cost of asset
    dsType::  !SellType
} deriving(Show,Generic,ToJSON,FromJSON)


{-# INLINABLE dsAsset #-}
dsAsset :: DirectSale -> AssetClass 
dsAsset ds=AssetClass (dsPaymentCurrency ds, dsPaymentTokenName ds) 

PlutusTx.makeIsDataIndexed ''DirectSale [('DirectSale, 0)]

-- total amount received by all the seller parties
{-# INLINABLE dsCostExcludingFee #-}
dsCostExcludingFee::Market-> DirectSale->Integer
dsCostExcludingFee  Market{mPrimarySaleFee,mSecondarySaleFee} DirectSale{dsCost,dsType} =
    (userShare * dsCost) `divide` marketHundredPercent
  where
    userShare=marketHundredPercent - case dsType  of
                                        Secondary -> mSecondarySaleFee
                                        Primary   -> mPrimarySaleFee

-- List of payment values to be payed to all the parties in directsale
{-# INLINABLE dsPaymentValueList #-}
dsPaymentValueList:: Market -> DirectSale  -> Integer -> [(PubKeyHash ,Integer)]
dsPaymentValueList market ds@DirectSale{dsSeller} strayAmount =  [(dsSeller,sellerValue)] <> partiesValue
    where
        totalReceived= dsCostExcludingFee market ds
        partyShare  percent = (totalReceived  * percent ) `divide` marketHundredPercent

        partiesValue  = map ( \(pkh,percent)-> (pkh,partyShare percent)) (dsSplits ds)
        sellerValue  =totalReceived - sum (map snd partiesValue) + strayAmount

-- market fee to be payed when buying directsale
{-# INLINABLE dsFee #-}
dsFee :: Market -> DirectSale -> Integer
dsFee market ds@DirectSale{dsCost}=dsCost - dsCostExcludingFee market ds

{-# INLINABLE validateBuy #-}
validateBuy:: Market -> ScriptContext ->Bool
validateBuy market@Market{mTreasury,mPrimarySaleFee,mSecondarySaleFee} ctx=
       allowSingleScript ctx
    && traceIfFalse "Insufficient payment" areSellersPaid
    && traceIfFalse "Insufficient fees" isMarketFeePaid
    where
        info=scriptContextTxInfo ctx

        isMarketFeePaid = valuePaidTo info mTreasury `geq` totalMarketFee
        areSellersPaid  = validatePayment (\pkh v-> valuePaidTo info pkh `geq` v) totalSellerPayment

        totalSellerPayment  = foldMap  sellerPartyPayment salesWithTxOut
        totalMarketFee      = foldMap  marketFeeValue salesWithTxOut

        marketFeeValue    (_,dsale)  = assetClassValue (dsAsset dsale ) $ dsFee market dsale
        sellerPartyPayment (txOut,dsale) = assetClassPayment (dsAsset dsale ) (dsPaymentValueList market dsale (assetClassValueOf (txOutValue txOut) (dsAsset dsale)))

        salesWithTxOut:: [(TxOut,DirectSale)]
        salesWithTxOut = ownInputsWithDatum ctx

      

{-# INLINABLE mkMarket #-}
mkMarket :: Market ->  DirectSale   -> MarketRedeemer -> ScriptContext    -> Bool
mkMarket market@Market{mOperator} ds@DirectSale{dsSeller}  action ctx =
    case  action of
        Buy       -> validateBuy market ctx
        Withdraw  -> traceIfFalse "Missing signatures" ( txSignedBy  info dsSeller || (txSignedBy info mOperator && isOwnerPaid) )
    where
      isOwnerPaid= valuePaidTo  info dsSeller `geq` (ownInputValue ctx <> negate  (txInfoFee info))
      info  =  scriptContextTxInfo ctx

{-# INLINABLE mkWrappedMarket #-}
mkWrappedMarket :: Market -> BuiltinData -> BuiltinData -> BuiltinData -> ()
mkWrappedMarket  m d r c = check $ mkMarket m (unsafeFromBuiltinData d) (unsafeFromBuiltinData r) (unsafeFromBuiltinData c)

marketValidator :: Market -> Validator
marketValidator market = mkValidatorScript  $
            $$(PlutusTx.compile [|| mkWrappedMarket ||])
            `applyCode` PlutusTx.liftCode market

marketScript :: Market -> Script
marketScript market =  unValidatorScript  (marketValidator market)