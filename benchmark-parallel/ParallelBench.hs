{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

module Main where

import Cardano.Api
  ( AddressAny (AddressShelley),
    AddressInEra (AddressInEra),
    AsType (AsAddressAny, AsAddressInEra, AsPaymentKey, AsSigningKey),
    AssetId (AdaAssetId, AssetId),
    BabbageEra,
    CardanoEra (BabbageEra),
    CardanoMode,
    IsCardanoEra,
    Key,
    LocalNodeConnectInfo,
    NetworkId (Testnet),
    NetworkMagic (NetworkMagic),
    PaymentKey,
    PolicyId (PolicyId),
    ScriptData,
    SerialiseAddress (deserialiseAddress, serialiseAddress),
    SerialiseAsCBOR (deserialiseFromCBOR),
    SerialiseAsRawBytes (deserialiseFromRawBytes),
    ShelleyBasedEra (ShelleyBasedEraAlonzo),
    SigningKey,
    TxId,
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
    hashScriptData,
    lovelaceToValue,
    negateValue,
    prettyPrintJSON,
    shelleyAddressInEra,
    valueFromList,
    valueToList,
    valueToLovelace,
  )
import Cardano.Api.Shelley (Address (ShelleyAddress), Lovelace (Lovelace), Quantity (Quantity), fromPlutusData, toShelleyAddr)
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers (parseAssetId, parseAssetIdText, parseAssetNQuantity, parseScriptData)
import Cardano.Kuber.Util (addrInEraToPkh, getDefaultSignKey, queryUtxos, readSignKey, skeyToAddr, skeyToAddrInEra)
import qualified Cardano.Ledger.Address as Shelley
import Cardano.Ledger.Crypto (StandardCrypto)
import Cardano.Marketplace.Common.ConsoleWritable (ConsoleWritable (toConsoleText))
import Cardano.Marketplace.V1.Core (buyToken, marketAddressShelley, marketScriptAddr, placeOnMarket, signAndSubmitTxBody)
import Cardano.Marketplace.V1.RequestModels
import Cardano.Marketplace.V1.ServerRuntimeContext (RuntimeContext (RuntimeContext), resolveContext)
import Control.Concurrent (MVar, forkIO, killThread, newMVar, putMVar, takeMVar, threadDelay, withMVar)
import Control.Concurrent.Async (forConcurrently, forConcurrently_, mapConcurrently, mapConcurrently_, withAsync)
import Control.Exception (SomeException (SomeException), try)
import Control.Monad (foldM, forM, forM_)
import Control.Monad.Reader (MonadIO (liftIO), ReaderT (runReaderT))
import Control.Monad.State
import Criterion.Main
import Criterion.Main.Options
import Criterion.Types (Config (verbosity), Verbosity (Verbose))
import qualified Data.ByteString.Char8 as BS8
import Data.Function (on)
import Data.IORef (IORef, atomicWriteIORef, newIORef, readIORef)
import Data.List.Split (chunksOf)
import qualified Data.Map as Map
import Data.Maybe (fromJust, fromMaybe, isJust, isNothing)
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import qualified Data.Text.IO as TIO
import GHC.Conc (atomically, newTVar)
import GHC.IO.Handle.FD (stdout)
import GHC.Int (Int64)
import ParallelUtils
import Plutus.Contracts.V1.Marketplace (DirectSale (..), Market (Market), SellType (Primary, Secondary), marketHundredPercent, percent)
import PlutusTx (Data (Map), toData)
import PlutusTx.Prelude (divide)
import System.Clock
import System.Directory (doesFileExist)
import System.Environment (getArgs, getEnv)
import System.IO (BufferMode (NoBuffering), IOMode (ReadMode), hFlush, hGetContents, hSetBuffering, openFile)
import System.Random (newStdGen)
import System.Random.Shuffle (shuffle')
import Text.Read (readMaybe)

testTokensStr = "fe0f87df483710134f34045b516763bad1249307dfc543bc56a9e738.testtoken"

defaultNoOfWallets = 1

getVasilChainInfo :: IO DetailedChainInfo
getVasilChainInfo = do
  sockEnv <- try $ getEnv "CARDANO_NODE_SOCKET_PATH"
  socketPath <- case sockEnv of
    Left (e::SomeException) -> error "Socket File is Missing: Set environment variable CARDANO_NODE_SOCKET_PATH"
    Right s -> pure s
  let networkId = Testnet (NetworkMagic 9)
      connectInfo = ChainConnectInfo $ localNodeConnInfo networkId socketPath
  withDetails connectInfo

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  putStrLn "\ESC[35m"

  putStrLn "Starting...\n"
  args <- getArgs
  let maybeNoOfWallets = case length args of
        0 -> Just defaultNoOfWallets
        _ -> readMaybe $ last args :: Maybe Int
  --Get no of wallets to be used in test from arguments if not present use defaultNoOfWallets
  let noOfWallets = fromMaybe defaultNoOfWallets maybeNoOfWallets
      requiredWallets = noOfWallets * 3

  dcInfo <- getVasilChainInfo

  let shouldSplit = not (null args) && head args == "split"
  -- Run Market operations if the second argument is run market with head args as split
  let shouldRunMarket = (length args >= 2 && args !! 1 == "runmarket" && head args == "split") || null args || length args == 1
  let shouldPrintUtxosOnly = not (null args) && head args == "print-utxos-only"
  let shouldMergeOnly = not (null args) && head args == "merge-utxos-only"

  wallets <- readWalletsFromFile requiredWallets

  if noOfWallets > 333
    then error "Currently max no of wallets supported are 333 since total used are 333 * 3 = 999"
    else do
      if shouldPrintUtxosOnly then do
        printUtxoOfWallets dcInfo wallets
      else if shouldMergeOnly then do
        mergeUtxosOfWallets dcInfo wallets
      else do
        testAsset <- parseAssetIdText $ T.pack testTokensStr
        fundedSignKey <- readSignKey "/home/krunx/.cardano/default.skey"

        -- printUtxoOfWallet dcInfo fundedSignKey

        wallets <- setupWallets wallets dcInfo testAsset fundedSignKey

        -- Setup step for collatral until vasil collateral is used
        if shouldSplit then
          splitUtxosOfWallets dcInfo wallets else putStrLn "Warning: Skipping split of utxos for collateral."

        if shouldRunMarket then do
          rng <- newStdGen
          let shuffledWallets = shuffle' wallets (length wallets) rng
          performMarketBench dcInfo noOfWallets shuffledWallets testAsset fundedSignKey
        else putStrLn "Warning: Skipping market benchmark."

        putStrLn "\nFinished..."

readWalletsFromFile :: Int -> IO [SigningKey PaymentKey]
readWalletsFromFile noOfWallets = do
  readHandle <- openFile "1000-wallets.txt" ReadMode
  content <- hGetContents readHandle
  let linesOfFile = lines content
      walletStrs = take noOfWallets linesOfFile
  mapM parseSigningKey walletStrs

-- TODO Refactor and remove unused code
setupWallets :: [SigningKey PaymentKey] -> DetailedChainInfo -> AssetId -> SigningKey PaymentKey -> IO [SigningKey PaymentKey]
setupWallets wallets dcInfo testAssetId fundedSignKey = do
  let walletsAddrs = map (\s -> AddressShelley $ skeyToAddr s (getNetworkId dcInfo)) wallets
  utxosE <- queryUtxos (getConnectInfo dcInfo) $ Set.fromList walletsAddrs
  utxos@(UTxO utxoMap) <- case utxosE of
    Left err -> error $ "Error getting utxos: " ++ show err
    Right utxos -> return utxos

  let utxoList = Map.toList utxoMap
      addrValueMap =
        foldl
          ( \newMap utxo@(_, TxOut aie (TxOutValue _ newValue) _ _) ->
              let addr = toShelleyAddr aie
               in case Map.lookup addr newMap of
                    Nothing -> Map.insert addr newValue newMap
                    Just existingValue -> Map.insert addr (existingValue <> newValue) newMap
          )
          Map.empty
          utxoList

      walletsAddrsInShelley = map (\s -> skeyToAddrInEra s (getNetworkId dcInfo)) wallets
      walletsWithNoUtxos = filter (\addr -> isNothing $ Map.lookup (toShelleyAddr addr) addrValueMap) walletsAddrsInShelley
      balancesWithLess = Map.filter (\v -> not $ v `valueGte` valueFromList [(AdaAssetId, Quantity 20_000_000), (testAssetId, Quantity 10)]) addrValueMap
      balancesWithLessAddrs = walletsWithNoUtxos <> map (\(Shelley.Addr nw pc scr, _) -> shelleyAddressInEra $ ShelleyAddress nw pc scr) (Map.toList balancesWithLess)

  if not (null balancesWithLessAddrs)
    then do
      putStrLn "Wallets with not enough value in them\n"
      print $ map (\a -> show (serialiseAddress a) ++ "0 Ada") balancesWithLessAddrs
      pPrint balancesWithLess
      --TODO Already split the utxo into chunks of main wallet
      let walletAddrsChunks = chunksOf 100 balancesWithLessAddrs
      mapM_
        ( \walletChunk -> do
            putStrLn $ "Funding wallet chunk " ++ show (length walletChunk)
            fundWallets dcInfo walletChunk fundedSignKey
            -- fundWalletsWithAdaOnly dcInfo walletChunk fundedSignKey
        )
        walletAddrsChunks
      print "Wallet funding completed."
    else print "All wallets have enough value."

  pure wallets
  where
    fundWallets :: ChainInfo v => v -> [AddressInEra BabbageEra] -> SigningKey PaymentKey -> IO ()
    fundWallets dcInfo walletAddrs fundedSignKey = do
      let fundAddr = getAddrEraFromSignKey dcInfo fundedSignKey
          utxoValue = valueFromList [(AdaAssetId, Quantity 100_000_000), (testAssetId, Quantity 1000)]
          addressesWithValue = map (,utxoValue) walletAddrs
          tokenAnd100AdaPayOperation = foldMap (uncurry txPayTo) addressesWithValue
          txOperations = tokenAnd100AdaPayOperation <> txWalletAddress fundAddr
      txBodyE <- txBuilderToTxBodyIO dcInfo txOperations
      txBody <- case txBodyE of
        Left err -> error $ "Error building tx: " ++ show err
        Right txBody -> return txBody
      tx <- signAndSubmitTxBody (getConnectInfo dcInfo) txBody [fundedSignKey]
      let txHash = getTxId $ getTxBody tx
      putStrLn $ "\nSubmitted successfully TxHash " ++ show txHash
      --Wait for single transaction to complete
      let firstAddrAny = getAddrAnyFromEra $ fst $ head addressesWithValue
      putStrLn "Wait for funds to appear on wallet."
      pollForTxId dcInfo firstAddrAny txHash

    fundWalletsWithAdaOnly :: ChainInfo v => v -> [AddressInEra BabbageEra] -> SigningKey PaymentKey -> IO ()
    fundWalletsWithAdaOnly dcInfo walletAddrs fundedSignKey = do
      let fundAddr = getAddrEraFromSignKey dcInfo fundedSignKey
          utxoValue = valueFromList [(AdaAssetId, Quantity 100_000_000)]
          addressesWithValue = map (,utxoValue) walletAddrs
          tokenAnd100AdaPayOperation = foldMap (uncurry txPayTo) addressesWithValue
          txOperations = tokenAnd100AdaPayOperation <> txWalletAddress fundAddr
      txBodyE <- txBuilderToTxBodyIO dcInfo txOperations
      txBody <- case txBodyE of
        Left err -> error $ "Error building tx: " ++ show err
        Right txBody -> return txBody
      tx <- signAndSubmitTxBody (getConnectInfo dcInfo) txBody [fundedSignKey]
      let txHash = getTxId $ getTxBody tx

      putStrLn $ "\nSubmitted successfully TxHash " ++ show txHash

      --Wait for single transaction to complete
      let firstAddrAny = getAddrAnyFromEra $ fst $ head addressesWithValue
      putStrLn "Wait for funds to appear on wallet."
      pollForTxId dcInfo firstAddrAny txHash

type Wallet = SigningKey PaymentKey

calculateAverage items = sum items `div` fromIntegral (length items)


performMarketBench :: DetailedChainInfo -> Int -> [SigningKey PaymentKey] -> AssetId -> SigningKey PaymentKey -> IO ()
performMarketBench dcInfo noOfWallets wallets testAsset fundedSignKey = do
  edcInfo <- resolveContext dcInfo
  case edcInfo of
    Left error -> putStrLn $ "RuntimeConfigurationError:\n - " ++ show error
    Right (RuntimeContext _ market _ _ _ _) -> do
      startTime <- getTimeInSec

      let loopArray = [0 .. (noOfWallets -1)]
      lock <- newMVar ()
      let atomicPutStrLn str = withMVar lock (\_ -> putStrLn str)
      let atomicPutStr str = withMVar lock (\_ -> putStr str)

      -- Generate new sets of wallets for primary seller, buyer and secondary buyers fund them and wait for transaction to complete
      -- and print the time taken to fund the wallets
      let walletsTuples = getWalletSets noOfWallets wallets

      queryLock <- newMVar ()
      let atomicQueryUtxos addrAny =
            withMVar
              queryLock
              ( \_ -> do
                  utxosE <- queryUtxos (getConnectInfo dcInfo) $ Set.singleton addrAny
                  case utxosE of
                    Left err -> error $ "Error getting utxos: " ++ show err
                    Right utxos -> return utxos
              )

      -- Spawn new thread for querying market utxos
      marketState <- newMarketState
      let marketAddress = marketAddressShelley market (getNetworkId dcInfo)
      let marketAddrAny = getAddrAnyFromEra marketAddress
      tId <- forkIO $ pollMarketUtxos dcInfo marketAddrAny marketState atomicQueryUtxos atomicPutStrLn

      -- Perform market operations parrallely for each set of seller and buyers wallet indepdently and at last payback to funded wallet
      results <- forConcurrently loopArray $ \index -> do
            performMarketOperation dcInfo testAsset index market walletsTuples atomicPutStrLn atomicPutStr fundedSignKey marketState marketAddrAny atomicQueryUtxos

      finishedTime <- getTimeInSec
      -- performMarketOperation dcInfo testAsset index market startTime walletsTuples atomicPutStrLn atomicPutStr fundedSignKey marketState marketAddrAny atomicQueryUtxos

      print results

      --TODO Use foldl and other alternatives but for now copy paste
      -- Calculate average time taken by wallets from times
      let times = map (\(a,_,_,_,_,_,_,_,_)->a) results
      let averageTime = sum times `div` fromIntegral (length times)

      let priSellFees = map (\(_,(psf,_),_,_,_,_,_,_,_)->psf) results
      let avgPriSellFee = sum priSellFees `div` fromIntegral (length priSellFees)

      let priBuyFees = map (\(_,_,(pbf,_),_,_,_,_,_,_)->pbf) results
      let avgPriBuyFee = sum priBuyFees `div` fromIntegral (length priBuyFees)

      let secSellFees = map (\(_,_,_,(ssf,_),_,_,_,_,_)->ssf) results
      let avgSecSellFee = sum secSellFees `div` fromIntegral (length secSellFees)

      let secBuyFees = map (\(_,_,_,_,(sbf,_),_,_,_,_)->sbf) results
      let avgSecBuyFee = sum secBuyFees `div` fromIntegral (length secBuyFees)

      let priSellSizes = map (\(_,_,_,_,_,pss,_,_,_)->pss) results
      let avgPriSellSize = sum priSellSizes `div` fromIntegral (length priSellSizes)

      let priBuySizes = map (\(_,_,_,_,_,_,pbs,_,_)->pbs) results
      let avgPriBuySize = sum priBuySizes `div` fromIntegral (length priBuySizes)

      let secSellSizes = map (\(_,_,_,_,_,_,_,sss,_)->sss) results
      let avgSecSellSize = sum secSellSizes `div` fromIntegral (length secSellSizes)

      let secBuySizes = map (\(_,_,_,_,_,_,_,_,sbs)->sbs) results
      let avgSecBuySize = sum secBuySizes `div` fromIntegral (length secBuySizes)


      forM_ results $ \(time,priSellFee,priBuyFee,secSellFee,secBuyFee,priSellSize,priBuySize,secSellSize,secBuySize) -> do
        putStrLn $
          "Time " ++ getDiffInSec time ++
          " Pri sell fee: " ++ show priSellFee ++
          " Pri buy fee: " ++ show priBuyFee ++
          " Sec sell fee: " ++ show secSellFee ++
          " Sec buy fee: " ++ show secBuyFee ++
          " Pri sell size: " ++ show priSellSize ++ " bytes"++
          " Pri buy size: " ++ show priBuySize ++ " bytes"++
          " Sec sell size: " ++ show secSellSize ++ " bytes"++
          " Sec buy size: " ++ show secBuySize ++ " bytes"


      printInGreen $ "\n Average Primary Sell Fee: " ++ show avgPriSellFee
      printInGreen $ "\n Average Primary Buy Fee: " ++ show avgPriBuyFee
      printInGreen $ "\n Average Secondary Sell Fee: " ++ show avgSecSellFee
      printInGreen $ "\n Average Secondary Buy Fee: " ++ show avgSecBuyFee
      printInGreen $ "\n Average Primary Sell Size: " ++ show avgPriSellSize
      printInGreen $ "\n Average Primary Buy Size: " ++ show avgPriBuySize
      printInGreen $ "\n Average Secondary Sell Size: " ++ show avgSecSellSize
      printInGreen $ "\n Average Secondary Buy Size: " ++ show avgSecBuySize
      printDiffInSec "\n Time taken on performing whole market operation for all wallets" startTime finishedTime
      printAlreadyCalculatedDiffInSecAtomic "\n Average Time taken by each wallet set on performing whole market cycle " averageTime atomicPutStrLn

  where
    -- loopedPerformMarketOpetaion :: DetailedChainInfo -> AssetId -> Int -> Market -> ([Wallet],[Wallet],[Wallet]) -> (String -> IO ()) -> (String -> IO ()) -> Wallet -> MarketUTxOState -> AddressAny -> (AddressAny -> IO (UTxO BabbageEra)) -> IO Int64
    -- loopedPerformMarketOpetaion dcInfo testAsset index market walletsTuples atomicPutStrLn atomicPutStr fundedSignKey marketState marketAddrAny atomicQueryUtxos = do
    --   result <- try (performMarketOperation dcInfo testAsset index market walletsTuples atomicPutStrLn atomicPutStr fundedSignKey marketState marketAddrAny atomicQueryUtxos) :: IO (Either SomeException Int64)
    --   case result of
    --     Left any -> do
    --       -- threadDelay 5_000_000
    --       print any
    --       loopedPerformMarketOpetaion dcInfo testAsset index market walletsTuples atomicPutStrLn atomicPutStr fundedSignKey marketState marketAddrAny atomicQueryUtxos
    --     Right res -> pure res

getWalletListOfIndex index (priSellers, priBuyers, secBuyers) = [priSellers !! index, priBuyers !! index, secBuyers !! index]

getSingleWallets index (priSellers, priBuyers, secBuyers) = (priSellers !! index, priBuyers !! index, secBuyers !! index)

-- Perform primary sell, primary buy, secondary sell and secondary buy with roaylty checking
performMarketOperation ::
  DetailedChainInfo ->
  AssetId ->
  Int ->
  Market ->
  ([SigningKey PaymentKey], [SigningKey PaymentKey], [SigningKey PaymentKey]) ->
  (String -> IO ()) ->
  (String -> IO ()) ->
  SigningKey PaymentKey ->
  MarketUTxOState ->
  AddressAny ->
  (AddressAny -> IO (UTxO BabbageEra)) ->
  IO (Int64,(Integer,String),(Integer,String),(Integer,String),(Integer,String),Int,Int,Int,Int)
performMarketOperation dcInfo testAsset index market walletTuples atomicPutStrLn atomicPutStr fundedSignKey marketState marketAddrAny atomicQueryUtxos = do
  let (priSeller, priBuyer, secBuyer) = getSingleWallets index walletTuples

  -- splitUtxosOfWallets dcInfo [priBuyer,secBuyer]

  marketCycleStartTime <- getTimeInSec
  --Primary sell
  priSellTx@(TxResponse priSellTxRes _,_,_) <-
  -- performPrimarySale dcInfo testAsset market marketAddrAny priSeller index atomicPutStrLn atomicPutStr marketState atomicQueryUtxos
    loopedPerformPrimarySale priSeller

  let priSellFee = getTxFee priSellTxRes
  let priSellSize = getCborTxSize priSellTxRes


  afterPrimarySellTime <- getTimeInSec
  printDiffInSecAtomic ("\nTime taken on placing token to market for Wallet Set " ++ show index) marketCycleStartTime afterPrimarySellTime atomicPutStrLn

  --Primary buy
  priBuyTx@(_,_,TxResponse priBuyTxRes _) <-
  -- performBuy dcInfo testAsset market priSellTx priBuyer priSeller index atomicPutStrLn atomicPutStr "primary " atomicQueryUtxos marketState marketAddrAny
    loopedPerformBuy priSellTx priBuyer priSeller "Primary "

  let priBuyFee = getTxFee priBuyTxRes
  let priBuySize = getCborTxSize priBuyTxRes

  afterPrimaryBuyTime <- getTimeInSec
  printDiffInSecAtomic ("\nTime taken on primary buying token from the market for Wallet Set " ++ show index) afterPrimarySellTime afterPrimaryBuyTime atomicPutStrLn

  --Seconday sell
  secSellTx@(TxResponse secSellTxRes _,_,_) <-
  -- performSecondarySale dcInfo testAsset market marketAddrAny priBuyer priSeller index atomicPutStrLn atomicPutStr marketState atomicQueryUtxos
    loopedPerformSecondarySale priSeller priBuyer

  let secSellFee = getTxFee secSellTxRes
  let secSellSize = getCborTxSize secSellTxRes

  afterSecondarySellTime <- getTimeInSec
  printDiffInSecAtomic ("\nTime taken on placing secondary token to the market for Wallet Set " ++ show index) afterPrimaryBuyTime afterSecondarySellTime atomicPutStrLn

  --Secondary buy
  secBuyTx@(_,_,TxResponse secBuyTxRes _) <-
  -- performBuy dcInfo testAsset market secSellTx secBuyer priBuyer index atomicPutStrLn atomicPutStr "secondary " atomicQueryUtxos marketState marketAddrAny
    loopedPerformBuy secSellTx secBuyer priBuyer "Secondary "

  let secBuyFee = getTxFee secBuyTxRes
  let secBuySize = getCborTxSize secBuyTxRes

  marketCycelEndTime <- getTimeInSec
  printDiffInSecAtomic ("\nTime taken on secondary buy of token from the market for Wallet Set " ++ show index) afterSecondarySellTime marketCycelEndTime atomicPutStrLn

  printDiffInSecAtomic ("\nTime taken for Wallet Set " ++ show index ++ " to complete market operation") marketCycleStartTime marketCycelEndTime atomicPutStrLn

  atomicPutStrLn ("Finished performing market operations for Wallet Set " ++ show index)
  pure (marketCycelEndTime - marketCycleStartTime,priSellFee,priBuyFee,secSellFee,secBuyFee,priSellSize,priBuySize,secSellSize,secBuySize)


  where
    loopedPerformPrimarySale priSeller = do
      result <- try (performPrimarySale dcInfo testAsset market marketAddrAny priSeller index atomicPutStrLn atomicPutStr marketState atomicQueryUtxos) :: IO (Either SomeException (TxResponse, TxId, ScriptData))
      case result of
        Left any -> do
          atomicPutStrLn "Error in performing primary sell"
          atomicPutStrLn $ show any
          loopedPerformPrimarySale priSeller
        Right res -> pure res

    loopedPerformSecondarySale priSeller priBuyer = do
      result <- try (performSecondarySale dcInfo testAsset market marketAddrAny priBuyer priSeller index atomicPutStrLn atomicPutStr marketState atomicQueryUtxos) :: IO (Either SomeException (TxResponse, TxId, ScriptData))
      case result of
        Left any -> do
          atomicPutStrLn "Error in secondary sell"
          atomicPutStrLn $ show any
          loopedPerformSecondarySale priSeller priBuyer
        Right res -> pure res

    loopedPerformBuy sellTx buyer prevSeller buyType = do
      result <-
        try
          ( performBuy dcInfo testAsset market sellTx buyer prevSeller index atomicPutStrLn atomicPutStr buyType atomicQueryUtxos marketState marketAddrAny
          ) ::
          IO (Either SomeException (SigningKey PaymentKey, AddressAny, TxResponse))
      case result of
        Left any -> do
          atomicPutStrLn "Error in performing buy"
          atomicPutStrLn $ show any
          loopedPerformBuy sellTx buyer prevSeller buyType
        Right res -> pure res

-- Perform primary sell from primary seller set of wallets
performPrimarySale dcInfo testAsset market marketAddrAny priSellerWallet index atomicPutStrLn atomicPutStr marketState atomicQueryUtxos = do
  let primaryCost = (AdaAssetId, Quantity 2_000_000)

  --Direct sell from all wallet without waiting
  atomicPutStrLn ("\nPerforming primary sell from wallet Set " ++ show index)
  priSellTx@(_, txId, _) <- performSingleSale dcInfo testAsset False market priSellerWallet [] primaryCost index atomicPutStrLn atomicQueryUtxos

  --Now watch for market for tx id to appear in market address
  atomicPutStrLn ("\nWait for primary sell transaction to appear on market address for Wallet Set " ++ show index)

  watchMarketForTxId dcInfo txId index atomicPutStrLn atomicPutStr marketState marketAddrAny "Primary Sell "

  --TODO check if values are deducted on wallet with printing it
  -- printUtxoOfWalletAtomic dcInfo priSellerWallet index atomicPutStrLn

  return priSellTx

-- Perfrom secondary sale from placing royalty party as primary sellers
performSecondarySale dcInfo testAsset market marketAddrAny secSeller priSeller index atomicPutStrLn atomicPutStr marketState atomicQueryUtxos = do
  --Perform secondary sell from buyers wallet without waiting
  atomicPutStrLn ("\nPerform secondary sell from previouos buyer wallet using roalty parties as previous primary seller for Wallet " ++ show index)
  let roaltyPercentToReqParty = 50_000_000
      primarySellerAddr = skeyToAddrInEra priSeller (getNetworkId dcInfo)
      secondaryCost = (AdaAssetId, Quantity 2_000_000)
  secSellTx@(_, txId, _) <- performSingleSale dcInfo testAsset True market secSeller [] secondaryCost index atomicPutStrLn atomicQueryUtxos

  --Waiting for transaction completion
  atomicPutStrLn ("\nWait for secondary sell transaction to appear on market address for Wallet Set " ++ show index)
  watchMarketForTxId dcInfo txId index atomicPutStrLn atomicPutStr marketState marketAddrAny "Secondary Sell "
  return secSellTx

-- Perfrom single sale of placing token in the market from single seller wallet
performSingleSale ::
  DetailedChainInfo ->
  AssetId ->
  Bool ->
  Market ->
  SigningKey PaymentKey ->
  [ShareModal] ->
  (AssetId, Quantity) ->
  Int ->
  ([Char] -> IO a3) ->
  (AddressAny -> IO (UTxO BabbageEra)) ->
  IO (TxResponse, TxId, ScriptData)
performSingleSale dcInfo testAsset isSecondary market sellerWallet sReqParties cost index atomicPutStrLn atomicQueryUtxos = do
  let model =
        SellReqModel
          { sreqParties = sReqParties,
            sreqAsset = CostModal (testAsset, 1),
            sreqCost = CostModal cost,
            isSecondary = isSecondary
          }
  let sellerAddrInEra = skeyToAddrInEra sellerWallet (getNetworkId dcInfo)
      sellerAddrAny = getAddrAnyFromEra sellerAddrInEra
  sellerPkh <- addrInEraToPkh sellerAddrInEra
  directSaleDatum <- constructDirectSaleDatum sellerPkh model

  UTxO utxoMap <- atomicQueryUtxos sellerAddrAny
  let firstUtxoHavingGt4AdaOnly@(UTxO filteredUMap) = UTxO $ fst $ Map.splitAt 1 $ Map.filter (\(TxOut _ (TxOutValue _ v) _ _) -> case valueToLovelace v of
        Just (Lovelace l) -> l > 5
        Nothing -> False) utxoMap
      collateralTxIn = head $ Map.keys filteredUMap

  let otherUtxos = Map.filterWithKey (\k _ -> k /= collateralTxIn ) utxoMap

  let lockedValue = valueFromList [(testAsset, 1), (AdaAssetId, 2_000_000)]
      txOperations =
        txPayToScript (marketScriptAddr dcInfo market) lockedValue (hashScriptData directSaleDatum)
          <> txAddTxInCollateral collateralTxIn
          <> txWalletUtxos (UTxO otherUtxos)

  txResponse@(TxResponse txRaw datums) <- placeOnMarket' dcInfo txOperations sellerWallet
  -- loopedSellIfFail txOperations
  -- placeOnMarket' dcInfo txOperation sellerWallet
  let txId = txIdFromTxResponse txResponse
  -- placeOnMarket dcInfo market model
  atomicPutStrLn $ "Submitted Tx Id : " ++ show txId ++ "for Wallet Set " ++ show index
  return (txResponse, txId, directSaleDatum)
  -- where
    --TODO better exception handling currently it loops for all failed
    -- loopedSellIfFail txOperations = do
    --   result <- try () :: IO (Either SomeException TxResponse)
    --   case result of
    --     Left any -> do
    --       print any
    --       loopedSellIfFail txOperations
    --     Right res -> pure res

placeOnMarket' :: ChainInfo v => v -> TxBuilder -> SigningKey PaymentKey -> IO TxResponse
placeOnMarket' dcInfo txOperations wallet = do
  -- putStrLn $ BS8.unpack $ prettyPrintJSON txOperations
  txBodyE <- txBuilderToTxBodyIO dcInfo txOperations
  txBody <- case txBodyE of
    Left err -> error $ "Error in creating transaction " ++ show err
    Right txBody -> return txBody
  tx <- signAndSubmitTxBody (getConnectInfo dcInfo) txBody [wallet]
  pure $ TxResponse tx []

--Perfrom buy from buyerwallets from the previous seller wallets that placed the token on the market

-- performBuy ::
--   DetailedChainInfo ->
--   AssetId ->
--   Market ->
--   (TxResponse, ScriptData) ->
--   SigningKey PaymentKey ->
--   SigningKey PaymentKey ->
--   Int ->
--   (String -> IO ()) ->
--   (String -> IO ()) ->
--   String ->
--   (AddressAny -> IO (UTxO AlonzoEra)) ->
--   (v -> IO DetailedChainInfo) ->
--   IO (SigningKey PaymentKey, AddressAny, TxId)
performBuy dcInfo testAsset market (_, sellTxId, datum) buyerWallet prevSellerWallet index atomicPutStrLn atomicPutStr buyType atomicQueryUtxos marketState marketAddrAny = do
  --Perform Primary buy of the token from another set of wallets
  atomicPutStrLn ("\nPerforming " ++ buyType ++ " buy for Wallet Set " ++ show index)

  buyTx@(_, addr, TxResponse tx _) <- performSingleBuy dcInfo buyerWallet testAsset sellTxId datum market atomicQueryUtxos
  -- performSingleBuy dcInfo buyerWallet testAsset datum artaConfig market
  let txId = getTxId $ getTxBody tx
  putStrLn $ "\nSubmitted successfully TxHash " ++ show txId
  --Wait for transaction to appear on buyers wallet
  atomicPutStrLn ("\nWait for bought token to appear on " ++ buyType ++ " buyer wallet. For Wallet Set " ++ show index)
  -- pollForTxId' dcInfo addr txId atomicPutStrLn atomicQueryUtxos

  watchMarketForTxIdDisappear dcInfo sellTxId index atomicPutStrLn atomicPutStr marketState (buyType ++ " Buy ")

  --TODO check for wallet valule with priting sellers and buyers wallet values
  -- printUtxoOfWalletAtomic dcInfo buyerWallet index atomicPutStrLn
  -- printUtxoOfWalletAtomic dcInfo prevSellerWallet index atomicPutStrLn

  return buyTx
  -- where
  --   --TODO better exception handling currently it loops for all failed
  --   loopedBuyIfFail = do
  --     result <- try (performSingleBuy dcInfo buyerWallet testAsset sellTxId datum market) :: IO (Either SomeException (SigningKey PaymentKey, AddressAny, TxId))
  --     case result of
  --       Left any -> do
  --         print any
  --         loopedBuyIfFail
  --       Right tuple -> pure tuple

-- Perfrom single buy from single wallet
performSingleBuy ::
  DetailedChainInfo ->
  SigningKey PaymentKey ->
  AssetId ->
  TxId ->
  ScriptData ->
  Market ->
  (AddressAny -> IO (UTxO BabbageEra)) ->
  IO (SigningKey PaymentKey, AddressAny, TxResponse)
performSingleBuy dcInfo buyerWallet tokenAsset sellTxId datum market atomicQueryUtxos= do
  let buyerAddr = getAddrEraFromSignKey dcInfo buyerWallet
      buyModel = BuyReqModel (TxContextAddressesReq (Just buyerWallet) Nothing Nothing Nothing Nothing Map.empty) Nothing (Just $ UtxoIdModal (sellTxId, TxIx 0)) (Just tokenAsset) datum Nothing
  txRes <- buyToken dcInfo market buyModel buyerAddr atomicQueryUtxos
  let buyerAddrAny = getAddrAnyFromEra buyerAddr
  return (buyerWallet, buyerAddrAny, txRes)

txIdFromTxResponse :: TxResponse -> TxId
txIdFromTxResponse (TxResponse tx _) = getTxId $ getTxBody tx

-- -- TODO Check royalty recevied or not for primary seller wallet that is placed as party when placing secondary sell
-- checkRoyalty dcInfo priSellTx secSellTx secBuyTx atomicPutStrLn = do
--     atomicPutStrLn "\nCheck for royalty recevied to roalty party sepecifed from secondary sell or not"

--     -- -- forM_ loopArray $ \index -> do
--     -- --     let (roaltyParty,_,_,_) = priSellTxs !! index
--     -- --     let (_,(_,Quantity secnondarySellCost),_,_) = secSellTxs !! index
--     -- --     let (secBuyer,secBuyerAddress,secBuyTxId) = secBuyTxs !! index

--     -- --     let totalValueAfterPlatformCut = secnondarySellCost - ((secnondarySellCost * 2_500_000) `divide` marketHundredPercent)
--     -- --     let valueForSreqParty = (totalValueAfterPlatformCut * roaltyPercentToReqParty) `divide` marketHundredPercent

--     -- --     let checkValue = valueFromList [(AdaAssetId , Quantity valueForSreqParty)]
--     -- --     roaltyPartyAddrAny <- getAddrAnyFromSignKey roaltyParty
--     -- --     pollForTxIdAndValueAtomic dcInfo roaltyPartyAddrAny secBuyTxId checkValue

-- performTransferBench :: Int -> IO ()
-- performTransferBench noOfWallets = do
--   dcInfo <- chainInfoTestnet
--   fundedSignKey <- getDefaultSignKey
--   let loopArray = [0 .. (noOfWallets -1)]
--   wallets <- forM loopArray $ \_ -> generateSigningKey AsPaymentKey

--   let utxoValue = valueFromList [(AdaAssetId, Quantity 4_000_000)]
--       walletsWithValue = map (,utxoValue) wallets
--       addressesWithValue = map (\(wallet, value) -> (skeyToAddrInEra wallet (getNetworkId dcInfo), value)) walletsWithValue
--       txOperation = foldMap (uncurry txPayTo) addressesWithValue
--       fundedAddr = getAddrEraFromSignKey dcInfo fundedSignKey

--   txBodyE <- txBuilderToTxBodyIO dcInfo txOperation
--   txBody <- case txBodyE of
--     Left err -> error $ "Error building tx: " ++ show err
--     Right txBody -> return txBody
--   tx <- signAndSubmitTxBody (getConnectInfo dcInfo) txBody [fundedSignKey]
--   let txHash = getTxId $ getTxBody tx

--   putStrLn $ "\nSubmitted successfully TxHash " ++ show txHash

--   --Wait for single transaction to complete
--   let firstAddrAny = getAddrAnyFromEra $ fst $ head addressesWithValue
--   putStrLn "Wait for funds to appear on wallet."
--   pollForTxId dcInfo firstAddrAny txHash

--   printLock <- newMVar ()
--   let atomicPutStrLn str = withMVar printLock (\_ -> putStrLn str)

--   queryLock <- newMVar ()
--   let atomicQueryUtxos addrAny = withMVar queryLock (\_ -> queryUtxos (getConnectInfo dcInfo) $ Set.singleton addrAny)

--   -- forConcurrently_ loopArray $ \index -> do
--   --Payback to funded wallet from all wallets and wait for transaction to complete

--   --Print utxos of all wallets
--   putStrLn "\nNow print funds available on all wallets."
--   printUtxoOfWallets dcInfo wallets

--   forConcurrently_ loopArray $ \index -> do
--     let wallet = wallets !! index
--     paybackToFundedWallet' dcInfo wallet index fundedSignKey atomicPutStrLn atomicQueryUtxos

--   -- mapConcurrently_ (\wallet-> paybackToFundedWallet' dcInfo wallet 0 fundedSignKey atomicPutStrLn atomicQueryUtxos) wallets

--   --Print utxos of funded wallet
--   putStrLn "Funds available on funding wallet after transferring to all wallets"
--   printUtxoOfWallet dcInfo fundedSignKey

--   -- Merger all utxos of funded wallet at last
--   mergeAllUtxos dcInfo fundedSignKey

hasAtleast :: Value -> Value -> Bool
hasAtleast _v2 _v1 = all (\(aid, Quantity q) -> q <= lookup aid) (valueToList _v1) -- do we find anything that's greater than q
  where
    lookup x = case Map.lookup x v2Map of
      Nothing -> 0
      Just (Quantity v) -> v
    v2Map = Map.fromList $ valueToList _v2

valueGte :: Value -> Value -> Bool
valueGte _vg _vl = not $ any (\(aid, Quantity q) -> q > lookup aid) (valueToList _vl) -- do we find anything that's greater than q
  where
    lookup x = case Map.lookup x v2Map of
      Nothing -> 0
      Just (Quantity v) -> v
    v2Map = Map.fromList $ valueToList _vg

valueLte :: Value -> Value -> Bool
valueLte _v1 _v2 = not $ any (\(aid, Quantity q) -> q > lookup aid) (valueToList _v1) -- do we find anything that's greater than q
  where
    lookup x = case Map.lookup x v2Map of
      Nothing -> 0
      Just (Quantity v) -> v
    v2Map = Map.fromList $ valueToList _v2
