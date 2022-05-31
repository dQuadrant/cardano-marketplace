{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

module ParallelUtils where

import Cardano.Api
  ( AddressAny,
    AddressInEra,
    AlonzoEra,
    AsType (AsAddressAny, AsAddressInEra, AsAlonzoEra, AsPaymentKey, AsSigningKey),
    AssetId (AdaAssetId, AssetId),
    AssetName (AssetName),
    CardanoMode,
    CtxUTxO,
    EraInMode (AlonzoEraInCardanoMode),
    Key,
    LocalNodeConnectInfo,
    PaymentKey,
    PolicyId (PolicyId),
    QueryInEra (QueryInShelleyBasedEra),
    QueryInMode (QueryInEra),
    QueryInShelleyBasedEra (QueryUTxO),
    QueryUTxOFilter (QueryUTxOByAddress),
    SerialiseAddress (deserialiseAddress, serialiseAddress),
    SerialiseAsRawBytes (deserialiseFromRawBytes),
    ShelleyBasedEra (ShelleyBasedEraAlonzo),
    SigningKey,
    TxIn (TxIn),
    TxIx (TxIx),
    TxOut (TxOut),
    TxOutValue (TxOutAdaOnly, TxOutValue),
    UTxO (UTxO),
    Value,
    deterministicSigningKey,
    deterministicSigningKeySeedSize,
    generateSigningKey,
    getTxBody,
    getTxId,
    lovelaceToValue,
    negateValue,
    queryNodeLocalState,
    serialiseToRawBytesHexText,
    valueFromList,
    valueToList,
    valueToLovelace,
    Value, prettyPrintJSON, Tx, TxBody
  )
import Cardano.Api.Shelley (Lovelace (Lovelace), Quantity (Quantity), fromPlutusData)
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers (parseAssetNQuantity, parseScriptData)
import Cardano.Kuber.Util
import qualified Cardano.Ledger.Address as Shelley
import Cardano.Marketplace.Common.ConsoleWritable (ConsoleWritable (toConsoleText), showStr)
import Cardano.Marketplace.V1.Core (buyToken, marketAddressShelley, placeOnMarket)
import Cardano.Marketplace.V1.RequestModels
import Cardano.Marketplace.V1.ServerRuntimeContext (RuntimeContext (..), resolveContext)
import Control.Concurrent (MVar, newMVar, putMVar, takeMVar, threadDelay, withMVar, readMVar)
import Control.Exception (SomeException (SomeException), try)
import Control.Monad (foldM, forM, forM_)
import Control.Monad.Reader (MonadIO (liftIO), ReaderT (runReaderT))
import Criterion.Main
import Criterion.Main.Options
import Criterion.Types (Config (verbosity), Verbosity (Verbose))
import Data.List.Split (chunksOf)
import Data.Map (keys)
import qualified Data.Map as Map
import Data.Maybe (fromMaybe)
import qualified Data.Set as Set
import Data.Text (Text, intercalate)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import qualified Data.Text.IO as TIO
import GHC.Conc (atomically, newTVar)
import GHC.IO.Handle.FD (stdout)
import GHC.Int (Int64)
import Plutus.Contracts.V1.Marketplace
import Plutus.V1.Ledger.Value (AssetClass (AssetClass))
import PlutusTx (toData)
import PlutusTx.Prelude (divide)
import System.Clock
import System.Environment (getArgs)
import System.IO (BufferMode (NoBuffering), hFlush, hSetBuffering)
import System.Random (randomRIO)
import Text.Read (readMaybe)
import qualified Data.ByteString.Char8 as BS8
import Control.Concurrent.Async (forConcurrently_)

--Convert to Addr any from Addr in era
getAddrAnyFromEra addrEra = fromMaybe (error "unexpected error converting address to another type") (deserialiseAddress AsAddressAny (serialiseAddress addrEra))

--Get Addr any from given sign key
getAddrAnyFromSignKey ctx signKey =
  getAddrAnyFromEra $ skeyToAddrInEra signKey (getNetworkId ctx)

--Get Addr in era from  given sign key
getAddrEraFromSignKey ctx signKey =
  skeyToAddrInEra signKey (getNetworkId ctx)

--Convert TxOutValue to Value
txOutValueToValue :: TxOutValue era -> Value
txOutValueToValue tv =
  case tv of
    TxOutAdaOnly _ l -> lovelaceToValue l
    TxOutValue _ v -> v

--Constrcut Direct Sale Datum from given a SellReqModel
constructDirectSaleDatum sellerPkh (SellReqModel (CostModal asset) parties (CostModal (costAsset, Quantity costAmount)) isSecondary) = do
  partiesData <- mapM toParty parties
  let AssetClass (currency, tokenName) = toPlutusAssetClass costAsset
      directSale =
        DirectSale
          { dsSeller = sellerPkh,
            dsSplits = partiesData,
            dsPaymentCurrency = currency,
            dsPaymentTokenName = tokenName,
            dsCost = costAmount,
            dsType = if isSecondary then Secondary else Primary
          }
  return (fromPlutusData $ toData directSale)
  where
    toParty (ShareModal (addr, v)) = do
      _pkh <- addrInEraToPkh addr
      pure (_pkh, v)

--Print utxo given a address
printUtxoOfAddr ctx addrAny atomicPutStrLn = do
  utxos <- loopedQueryUtxos ctx addrAny
  let balance = utxoSum utxos
      utxoCount = case utxos of UTxO map -> Map.size map
  atomicPutStrLn $ toConsoleText "  " balance

--Convert TimeSpec into seconds
getTimeInSec = do
  TimeSpec sec _ <- getTime Monotonic
  return sec

--Given t1 and t2 print the difference in time t2 - t1
printDiffInSec :: String -> Int64 -> Int64 -> IO ()
printDiffInSec printString t1 t2 = do
  let diff = t2 - t1
  if diff > 60
    then do
      let min = diff `div` 60
      let sec = diff `mod` 60
      printInGreen $ printString ++ " " ++ show min ++ " min " ++ show sec ++ " sec"
    else printInGreen $ printString ++ " " ++ show diff ++ " sec"

--Given t1 and t2 print the difference in time t2 - t1
printDiffInSecAtomic printString t1 t2 atomicPutStrLn = do
  let diff = t2 - t1
  if diff > 60
    then do
      let min = diff `div` 60
      let sec = diff `mod` 60
      printInGreenAtomic (printString ++ " " ++ show min ++ " min " ++ show sec ++ " sec") atomicPutStrLn
    else printInGreenAtomic (printString ++ " " ++ show diff ++ " sec") atomicPutStrLn

--Print in green text in console
printInGreenAtomic str atomicPutStrLn = do
  atomicPutStrLn $ "\n\ESC[92m" ++ str
  atomicPutStrLn "\ESC[35m"

--Print in green text in console
printInGreen str = do
  putStrLn $ "\n\ESC[92m" ++ str
  putStrLn "\ESC[35m"

printTxBuilder :: TxBuilder -> IO ()
printTxBuilder txBuilder = do
  putStrLn $ BS8.unpack $ prettyPrintJSON txBuilder

--Generate new sets of buyer and seller wallets and fund them from main funding wallet
generateAndFundWallets ctx noOfWallets testAsset fundedSignKey = do
  let loopArray = [0 .. (noOfWallets * 3 -1)]
  wallets <- forM loopArray $ \_ -> generateSigningKey AsPaymentKey

  let walletChunks = chunksOf noOfWallets wallets

  let (priSellers, priBuyers, secBuyers) = (head walletChunks, walletChunks !! 1, walletChunks !! 2)

  let priSellerUtxoValue = valueFromList [(AdaAssetId, Quantity 6_000_000), (testAsset, 1)]
  let priBuyerUtxoValue = valueFromList [(AdaAssetId, Quantity 10_000_000)]
  let secBuyerUtxoValue = valueFromList [(AdaAssetId, Quantity 10_000_000)]

  let priSellersWithValues = map (,priSellerUtxoValue) priSellers
  let priBuyersWithValues = map (,priBuyerUtxoValue) priBuyers
  let secBuyersdWithValues = map (,secBuyerUtxoValue) secBuyers

  let allWalletWithValues = priSellersWithValues ++ priBuyersWithValues ++ secBuyersdWithValues

  --Pay all wallet with their value required and wait for transaction to complete
  payAllAndWait ctx wallets allWalletWithValues fundedSignKey

  return (wallets, allWalletWithValues, priSellers, priBuyers, secBuyers)

getWalletSets :: Int -> [SigningKey PaymentKey] -> ([SigningKey PaymentKey], [SigningKey PaymentKey], [SigningKey PaymentKey])
getWalletSets noOfWallets wallets =
  let walletChunks = chunksOf noOfWallets wallets
      (priSellers, priBuyers, secBuyers) = (head walletChunks, walletChunks !! 1, walletChunks !! 2)
   in (priSellers, priBuyers, secBuyers)

--Pay funds to all wallets generated from main funding wallet
payAllAndWait :: DetailedChainInfo -> [SigningKey PaymentKey] -> [(SigningKey PaymentKey, Value)] -> SigningKey PaymentKey -> IO ()
payAllAndWait ctx wallets walletsWithValue fundedSignKey = do
  --Perform transaction where all wallets are funded by main funding wallet
  putStrLn "\nLoading intial funds to all wallets"
  putStrLn "Intital funds available on funding wallet"
  printUtxoOfWallet ctx fundedSignKey
  let walletAddreses = map (\(wallet, value) -> (skeyToAddrInEra wallet (getNetworkId ctx), value)) walletsWithValue
      txOperation = foldMap (uncurry txPayTo) walletAddreses
  let fundedAddr = getAddrEraFromSignKey ctx fundedSignKey
  txBodyE <- txBuilderToTxBodyIO ctx txOperation
  txBody <- case txBodyE of
    Left err -> error $ "Error creating transaction: " ++ show err
    Right txBody -> return txBody
  tx <- signAndSubmitTxBody (getConnectInfo ctx) txBody [fundedSignKey]
  let txHash = getTxId $ getTxBody tx
  putStrLn $ "\nSubmitted successfully TxHash " ++ show txHash

  --Wait for single transaction to complete
  let addrAny = getAddrAnyFromEra $ fst $ head walletAddreses
  putStrLn "Wait for funds to appear on wallet."
  pollForTxId ctx addrAny txHash

  --Print utxos of all wallets
  putStrLn "\nNow print funds available on all wallets."
  printUtxoOfWallets ctx wallets

  --Print utxos of funded wallet again after paying
  putStrLn "Funds available on funding wallet after transferring to all wallets"
  printUtxoOfWallet ctx fundedSignKey

--Payback from all wallets to main funded wallet and merge utxos of funded wallet
paybackToFundedWallet ctx wallet index atomicPutStrLn fundedSignKey = do
  atomicPutStrLn ("\nPerform payback to funded wallet from Wallet Set " ++ show index)

  let fundedAddr = getAddrEraFromSignKey ctx fundedSignKey
  let fundedAddrAny = getAddrAnyFromEra fundedAddr

  --Payback from all wallets to funded wallet without waiting to transaction to appear on funded wallet
  let newUtxoValue = valueFromList [(AdaAssetId, Quantity 2_000_000)]

  printUtxoOfWalletAtomic ctx wallet index atomicPutStrLn

  utxos <- getUtxosOfWallet ctx wallet

  let txOperation =
        txPayTo fundedAddr newUtxoValue
          <> txConsumeUtxos utxos
      addrEra = getAddrEraFromSignKey ctx wallet
  txBodyE <- txBuilderToTxBodyIO ctx txOperation
  txBody <- case txBodyE of
    Left err -> error $ "Error creating transaction: " ++ show err
    Right txBody -> return txBody
  tx <- signAndSubmitTxBody (getConnectInfo ctx) txBody [wallet]
  let txId = getTxId txBody

  atomicPutStrLn $ "\nWait for payback funds to appear on funding wallet. TxId: " ++ show txId ++ " For Wallet Set " ++ show index

  pollForTxId ctx fundedAddrAny txId

  atomicPutStrLn ("Payback to funded wallet completed from Wallet Set " ++ show index)

  printUtxoOfWalletAtomic ctx wallet index atomicPutStrLn
  printUtxoOfWalletAtomic ctx fundedSignKey index atomicPutStrLn

--Payback from all wallets to main funded wallet and merge utxos of funded wallet
-- paybackToFundedWallet' ::
--   IsNetworkCtx v =>
--   v ->
--   SigningKey PaymentKey ->
--   Int ->
--   SigningKey PaymentKey ->
--   ([Char] -> IO ()) ->
--   (AddressAny -> IO (UTxO AlonzoEra)) ->
--   IO ()
-- paybackToFundedWallet' ctx wallet index fundedSignKey atomicPutStrLn atomicQueryUtxos = do
--   atomicPutStrLn ("\nPerform payback to funded wallet from Wallet Set " ++ show index)

--   let fundedAddr = getAddrEraFromSignKey ctx fundedSignKey
--       fundedAddrAny = getAddrAnyFromEra fundedAddr

--   --Payback from all wallets to funded wallet without waiting to transaction to appear on funded wallet
--   let newUtxoValue = valueFromList [(AdaAssetId, Quantity 2_000_000)]

--   addrAny <- getAddrAnyFromSignKey ctx wallet
--   -- printUtxoOfWalletAtomic' ctx addrAny index atomicPutStrLn atomicQueryUtxos

--   utxos <- atomicQueryUtxos addrAny

--   let txOperation =
--         txPayTo fundedAddr newUtxoValue
--           <> txConsumeUtxos utxos
--   let addrEra = getAddrEraFromSignKey ctx wallet
--   TxResult _ _ _ txBody <- txBuilderToTxBodyIO ctx txOperation
--   tx <- signAndSubmitTxBody (networkCtxConn ctx) txBody [wallet]
--   let txId = getTxId txBody

--   atomicPutStrLn $ "\nWait for payback funds to appear on funding wallet. TxId: " ++ show txId ++ " For Wallet Set " ++ show index

--   pollForTxId' ctx fundedAddrAny txId atomicPutStrLn atomicQueryUtxos

-- atomicPutStrLn ("Payback to funded wallet completed from Wallet Set " ++ show index)

-- printUtxoOfWalletAtomic' ctx wallet index atomicPutStrLn atomicQueryUtxos
-- printUtxoOfWalletAtomic' ctx fundedSignKey index atomicPutStrLn atomicQueryUtxos

--Query and merge all utxos of given signkey
mergeAllUtxos ctx signKey = do
  let addrEra = getAddrEraFromSignKey ctx signKey
  let addrAny = getAddrAnyFromEra addrEra

  putStrLn $ "\nPerform merge utxos of wallet" ++ show signKey
  utxo@(UTxO utxosMap) <- loopedQueryUtxos ctx addrAny
  let utxosList = Map.toList utxosMap
  let len = length utxosList

  --If utxos length are greater then 100 then perform chunks merge.
  if len > 100
    then do
      let toChunksNum = len `div` 3
      print len
      let utxosChunk = chunksOf toChunksNum utxosList :: [[(TxIn, TxOut CtxUTxO AlonzoEra)]]
      forM_ utxosChunk $ \chunkedUtxos -> do
        let chunkedUtxosMap = Map.fromList chunkedUtxos
        let utxoObj = UTxO chunkedUtxosMap
        putStrLn "\n"
        mergeUtxos ctx utxoObj signKey addrEra addrAny
    else mergeUtxos ctx utxo signKey addrEra addrAny

--Merge utxos of any wallet given the signkey, address and utxos
mergeUtxos ctx utxos signKey addrEra addrAny = do
  let utxosSum = utxoSum utxos <> negateValue (lovelaceToValue $ Lovelace 5_000_000)
      txOperation = txPayTo addrEra utxosSum <> txConsumeUtxos utxos
  txBodyE <- txBuilderToTxBodyIO ctx txOperation
  txBody <- case txBodyE of
    Left err -> error $ "Error creating transaction: " ++ show err
    Right txBody -> return txBody
  tx <- signAndSubmitTxBody (getConnectInfo ctx) txBody [signKey]
  let txId = getTxId txBody
  putStrLn $ "Wait merge utxos to appear on wallet TxId: " ++ show txId
  pollForTxId ctx addrAny txId
  putStrLn "Wallet utxo merge completed."

-- printUtxoOfWallet ctx signKey

printUtxoOfWallets ctx wallets = do
  forM_ wallets $ \wallet -> printUtxoOfWallet ctx wallet

--Print all utxos of given wallet
printUtxoOfWalletAtomic :: DetailedChainInfo -> SigningKey PaymentKey -> Int -> ([Char] -> IO b) -> IO b
printUtxoOfWalletAtomic ctx wallet index atomicPutStrLn = do
  utxos <- getUtxosOfWallet ctx wallet
  let balance = utxoSum utxos
      utxoCount = case utxos of UTxO map -> Map.size map
  atomicPutStrLn $ "\nFor Wallet Set " ++ show index ++ " For wallet " ++ show wallet ++ " Utxo Count : " ++ show utxoCount
  atomicPutStrLn $ toConsoleText "  " balance

--Print all utxos of given wallet
printUtxoOfWalletAtomic' :: DetailedChainInfo -> AddressAny -> Int -> ([Char] -> IO ()) -> (AddressAny -> IO (UTxO AlonzoEra)) -> IO ()
printUtxoOfWalletAtomic' ctx addrAny index atomicPutStrLn atomicQueryUtxos = do
  utxos <- atomicQueryUtxos addrAny
  let balance = utxoSum utxos
      utxoCount = case utxos of UTxO map -> Map.size map
  atomicPutStrLn $ "\nFor Wallet Set " ++ show index ++ " For wallet " ++ show addrAny ++ " Utxo Count : " ++ show utxoCount
  atomicPutStrLn $ toConsoleText "  " balance

getUtxosOfWallet ::
  ChainInfo v => v ->
  SigningKey PaymentKey ->
  IO (UTxO AlonzoEra)
getUtxosOfWallet ctx wallet = do
  let addrAny = getAddrAnyFromSignKey ctx wallet
  loopedQueryUtxos ctx addrAny
  -- case utxos of
  --   Left err -> error $ "Error getting utxos: " ++ show err
  --   Right utxos -> return utxos

-- Pack the txIn in text format with # separated
renderTxIn :: TxIn -> Text
renderTxIn (TxIn txId (TxIx ix)) =
  serialiseToRawBytesHexText txId <> "#" <> T.pack (show ix)

renderTxOut :: TxOut CtxUTxO AlonzoEra -> Text
renderTxOut (TxOut _ txOutValue _) = do
  let value = txOutValueToValue txOutValue
  renderValue value

renderValue :: Value -> Text
renderValue v =
  T.intercalate
    "+"
    (map renderAsset $ valueToList v)

renderAsset :: (AssetId, Quantity) -> Text
renderAsset (ass, q) = T.pack $ case ass of
  AdaAssetId -> renderAda q
  AssetId p n -> show q ++ " " ++ showStr p ++ "." ++ showStr n

renderAda :: Quantity -> String
renderAda (Quantity q) = show ((fromIntegral q :: Double) / 1e6) ++ "Ada"

pPrint balances = do
  forM_ (Map.toList balances) $ \(Shelley.Addr _ s _, value) -> do
    TIO.putStrLn $ T.pack (show s) <> ": " <> renderValue value

--Print all utxos of given wallet
printUtxoOfWallet :: ChainInfo v => v -> SigningKey PaymentKey -> IO ()
printUtxoOfWallet ctx wallet = do
  utxos@(UTxO utxoMap) <- getUtxosOfWallet ctx wallet
  printUtxos utxos wallet

printUtxos :: UTxO AlonzoEra -> SigningKey PaymentKey -> IO ()
printUtxos utxos@(UTxO utxoMap) wallet = do
  putStrLn $ "\n\nUtxos " <> show wallet <> " Count: " <> show (Map.size utxoMap)
  forM_ (Map.toList utxoMap) $ \(txIn, txOut) -> do
    TIO.putStrLn $ " " <> renderTxIn txIn <> ": " <> renderTxOut txOut

  putStrLn "\nTotal balance: "
  let balance = utxoSum utxos
  putStrLn $ toConsoleText " " balance

printUtxosMap :: Map.Map TxIn (TxOut CtxUTxO AlonzoEra) -> IO ()
printUtxosMap utxoMap = do
  forM_ (Map.toList utxoMap) $ \(txIn, txOut) -> do
    TIO.putStrLn $ " " <> renderTxIn txIn <> ": " <> renderTxOut txOut

  putStrLn "\nTotal balance: "
  let balance = utxoMapSum utxoMap
  putStrLn $ toConsoleText " " balance


-- printUtxosWithoutTotal :: UTxO AlonzoEra -> AddressAny -> IO ()
printUtxosWithoutTotal utxos@(UTxO utxoMap) addrAny atomicPutStrLn = do
  atomicPutStrLn $ "\n\nUtxos for addr " <> show (serialiseAddress addrAny) <> " Count: " <> show (Map.size utxoMap)
  forM_ (Map.toList utxoMap) $ \(txIn, txOut) -> do
    atomicPutStrLn $ " " <> show (renderTxIn txIn) <> ": " <> show (renderTxOut txOut)

-- Watch market address for transaction id to appear
watchMarketForTxId txId index atomicPutStrLn atomicPutStr marketState@(MarketUTxOState m) = do
  threadDelay 1_000_000
  atomicPutStr "."
  atomicPutStrLn $ "Waiting for txId" ++ show txId

  let txIn = TxIn txId (TxIx 0)

  utxo@(UTxO utxoMap) <- readMVar m
  -- putMVar m utxo
  atomicPutStrLn $ "Size of map " ++ show (Map.size utxoMap) ++ show (renderTxIn txIn)
  let isTxIdPresent =  Map.member txIn utxoMap
 
  if isTxIdPresent
    then do
      atomicPutStrLn $ "\nTxId " <> show txId <> " found on market " <> show index
    else do
      watchMarketForTxId txId index atomicPutStrLn atomicPutStr marketState

loopedQueryUtxos :: ChainInfo v => v -> AddressAny -> IO (UTxO AlonzoEra)
loopedQueryUtxos ctx addrAny = do
  result <- try (queryUtxos (getConnectInfo ctx) $ Set.singleton addrAny) :: IO (Either SomeException (Either FrameworkError (UTxO AlonzoEra)))
  case result of
    Left any -> loopedQueryUtxos ctx addrAny
    Right utxosE -> case utxosE of
      Left err -> do
        print err
        loopedQueryUtxos ctx addrAny
      Right utxos -> return utxos

-- Poll for txId to appear in new utxos list each second
pollForTxId ctx addrAny txHash = do
  threadDelay 1000000
  utxos@(UTxO utxoMap) <- loopedQueryUtxos ctx addrAny
  putStr "."
  let txIdsKey = map (\(TxIn txId _) -> txId) $ Map.keys utxoMap
  if txHash `elem` txIdsKey
    then putStrLn "\nFunds Transferred successfully."
    else pollForTxId ctx addrAny txHash

pollForTxId' ctx addrAny txHash atomicPutStrLn atomicQueryUtxos = do
  threadDelay 1000000
  utxos@(UTxO utxoMap) <- atomicQueryUtxos addrAny
  putStr "."
  atomicPutStrLn $ "Poll for" ++ show txHash
  let txIdsKey = map (\(TxIn txId _) -> txId) $ Map.keys utxoMap
  if txHash `elem` txIdsKey
    then atomicPutStrLn "\nFunds Transferred successfully."
    else pollForTxId ctx addrAny txHash

--Poll for Tx id and value to be correctly appear
-- pollForTxIdAndValue ctx addrAny txId checkValue = do
--   threadDelay 1000000
--   utxos@(UTxO utxoMap) <- queryUtxos (networkCtxConn ctx) addrAny
--   -- prettyPrintUtxo txId utxos

--   putStr "."

--   --Generate list of txId as keys from utxoMap
--   let txIdsKey = map (\(TxIn txId _) -> txId) $ Map.keys utxoMap

--   if txId `elem` txIdsKey
--     then do
--       putStrLn "\nTransferred successfully."
--       --Get list of txId and value looking like map (txId, Value) association
--       let txIdValueList = map (\(TxIn txId _, TxOut _ txOutValue _) -> (txId, txOutValueToValue txOutValue)) $ Map.toList utxoMap
--       let txIdValueMap = Map.fromList txIdValueList
--       --Lookup value of txid passed from parameter
--       let valueMaybe = Map.lookup txId txIdValueMap
--       --Check for value
--       case valueMaybe of
--         Just value -> do
--           if value == checkValue then putStrLn "Req party has received roalty successfully" else error "Error: Value received by the roalty party is not same."
--         Nothing -> error "Error : Couldn't find the current txId into txIdValue map"
--     else pollForTxIdAndValue ctx addrAny txId checkValue

-- Poll for txId to appear in new utxos list each second
pollForTxIdAtomic ctx addrAny txHash index atomicPutStrLn atomicPutStr = do
  randomDealy <- randomRIO (1_000_000, 3_000_000) :: IO Int
  threadDelay randomDealy
  utxos@(UTxO utxoMap) <- loopedQueryUtxos ctx addrAny
  atomicPutStr "."
  let txIdsKey = map (\(TxIn txId _) -> txId) $ Map.keys utxoMap
  if txHash `elem` txIdsKey
    then atomicPutStrLn ("\nFunds Transferred successfully. For Wallet Set " ++ show index)
    else pollForTxIdAtomic ctx addrAny txHash index atomicPutStrLn atomicPutStr

--Poll for Tx id and value to be correctly appear
-- pollForTxIdAndValueAtomic ctx addrAny txId checkValue atomicPutStrLn atomicPutStr = do
--   threadDelay 1000000
--   utxos@(UTxO utxoMap) <- queryUtxos (networkCtxConn ctx) addrAny
--   -- prettyPrintUtxo txId utxos

--   atomicPutStr "."

--   --Generate list of txId as keys from utxoMap
--   let txIdsKey = map (\(TxIn txId _) -> txId) $ Map.keys utxoMap

--   if txId `elem` txIdsKey
--     then do
--       atomicPutStrLn "\nTransferred successfully."
--       --Get list of txId and value looking like map (txId, Value) association
--       let txIdValueList = map (\(TxIn txId _, TxOut _ txOutValue _) -> (txId, txOutValueToValue txOutValue)) $ Map.toList utxoMap
--       let txIdValueMap = Map.fromList txIdValueList
--       --Lookup value of txid passed from parameter
--       let valueMaybe = Map.lookup txId txIdValueMap
--       --Check for value
--       case valueMaybe of
--         Just value -> do
--           if value == checkValue then atomicPutStrLn "Req party has received roalty successfully" else error "Error: Value received by the roalty party is not same."
--         Nothing -> error "Error : Couldn't find the current txId into txIdValue map"
--     else pollForTxIdAndValueAtomic ctx addrAny txId checkValue atomicPutStrLn atomicPutStr

performQuery :: LocalNodeConnectInfo CardanoMode -> QueryInShelleyBasedEra AlonzoEra b -> IO b
performQuery conn q =
  do
    a <- queryNodeLocalState conn Nothing qFilter
    case a of
      Left af -> error $ "Error " ++ show af
      Right e -> case e of
        Left em -> error $ "Error " ++ show em
        Right uto -> pure $ uto
  where
    qFilter =
      QueryInEra AlonzoEraInCardanoMode $
        QueryInShelleyBasedEra ShelleyBasedEraAlonzo q

lockedPutStrLn str = do
  lock <- newMVar ()
  withMVar lock (\_ -> putStrLn str)

lockedPutStr str = do
  lock <- newMVar ()
  withMVar lock (\_ -> putStr str)

lockedFunction func = do
  lock <- newMVar ()
  withMVar lock (const func)

parseSigningKey :: String -> IO (SigningKey PaymentKey)
parseSigningKey sKeyStr = do
  let skeyBs = T.encodeUtf8 $ T.pack sKeyStr
  case deserialiseFromRawBytes (AsSigningKey AsPaymentKey) skeyBs of
    Nothing -> error "Error parsing signing key: "
    Just skey -> return skey

newtype MarketUTxOState = MarketUTxOState (MVar (UTxO AlonzoEra))

newMarketState :: IO MarketUTxOState
newMarketState = do
  m <- newMVar $ UTxO Map.empty
  return (MarketUTxOState m)

updateMarketUTxO :: UTxO AlonzoEra -> MarketUTxOState -> IO ()
updateMarketUTxO utxo (MarketUTxOState m) = do
  _ <- takeMVar m
  putMVar m utxo

-- lookupTxInInMarketUTxO :: MarketUTxOState -> TxIn -> IO Bool
-- lookupTxInInMarketUTxO (MarketUTxOState m) txIn atomicPutStrLn = do
  
--   utxo@(UTxO utxoMap) <- readMVar m
--   atomicPutStrLn $ "Size of map " ++ show (Map.size utxoMap) ++ show (renderTxIn txIn)
--   -- printUtxosMap utxoMap
--   -- putMVar m utxo
--   return (Map.member txIn utxoMap)

-- periodicallyPrint :: MarketUTxOState -> IO b
-- periodicallyPrint ms@(MarketUTxOState m) = do
--   threadDelay 1000000
--   print "Print utxo"
--   utxo@(UTxO utxoMap) <- takeMVar m
--   putMVar m utxo
--   print utxo
--   periodicallyPrint ms

pollMarketUtxos ctx marketAddrAny marketState atomicQueryUtxos atomicPutStrLn= do
  threadDelay 2000000
  utxo <- atomicQueryUtxos marketAddrAny
  printUtxosWithoutTotal utxo marketAddrAny atomicPutStrLn
  updateMarketUTxO utxo marketState
  pollMarketUtxos ctx marketAddrAny marketState atomicQueryUtxos atomicPutStrLn


splitUtxosOfWallets ctx wallets = do
  forConcurrently_ wallets $ \wallet -> do
    let addrEra = getAddrEraFromSignKey ctx wallet
        addrAny = getAddrAnyFromEra addrEra
    utxos@(UTxO utxoMap) <- getUtxosOfWallet ctx wallet
    -- Get utxos having less than 2 ada
    let utxosLessThan4Ada = Map.filter (\(TxOut _ (TxOutValue _ value) _) -> valueLte value (lovelaceToValue $ Lovelace 4_000_000)) utxoMap
    -- printUtxosMap utxosLessThan4Ada
    splitUtxos ctx utxos wallet addrEra addrAny

splitUtxos ctx utxos signKey addrEra addrAny = do
  let balance = utxoSum utxos
  let Quantity lovelaceQuantitySum = foldMap snd $ valueToList balance
  let noOfSplits = lovelaceQuantitySum `div` 1_000_000 `div` 5
  let splitValue = lovelaceToValue $ Lovelace 5_000_000
      payOperations = foldMap (\_->txPayTo addrEra splitValue) [1 .. noOfSplits-1]
      txOperations = payOperations
          <> txConsumeUtxos utxos
          <> txWalletAddress addrEra

  print noOfSplits
  printTxBuilder txOperations

  txBodyE <- loopedTxBuilderToTxBodyIo txOperations
  txBody <- case txBodyE of
    Left fe -> error $ "Error: " ++ show fe
    Right txBody -> pure txBody

  -- tx <- signAndSubmitTxBody (getConnectInfo ctx) txBody [signKey]
  tx <- loopedSubmitTx txBody
  let txId = getTxId txBody
  putStrLn $ "Wait split utxos to appear on wallet TxId: " ++ show txId
  -- pollForTxId ctx addrAny txId
  -- putStrLn "Wallet utxo split completed."

  where
    loopedTxBuilderToTxBodyIo txOperations = do
      result <- try (txBuilderToTxBodyIO ctx txOperations ) :: IO (Either SomeException (Either FrameworkError (TxBody AlonzoEra)))
      case result of
        Left any -> do
          print any
          loopedTxBuilderToTxBodyIo txOperations
        Right tx -> pure tx

    loopedSubmitTx txBody = do
      result <- try (signAndSubmitTxBody (getConnectInfo ctx) txBody [signKey] ) :: IO (Either SomeException (Tx AlonzoEra))
      case result of
        Left any -> do
          print any
          loopedSubmitTx txBody
        Right tx -> pure tx
        