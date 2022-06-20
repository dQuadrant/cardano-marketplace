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
    BabbageEra,
    AsType (AsAddressAny, AsAddressInEra, AsPaymentKey, AsSigningKey),
    AssetId (AdaAssetId, AssetId),
    CardanoEra (BabbageEra),
    IsCardanoEra,
    Key,
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
    shelleyAddressInEra,
    valueFromList,
    valueToList, hashScriptData, TxIx (TxIx), NetworkId (Testnet), LocalNodeConnectInfo, CardanoMode, NetworkMagic (NetworkMagic), prettyPrintJSON, valueToLovelace
  )
import Cardano.Api.Shelley (Address (ShelleyAddress), Lovelace (Lovelace), Quantity (Quantity), fromPlutusData, toShelleyAddr)
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers (parseAssetId, parseAssetIdText, parseAssetNQuantity, parseScriptData)
import Cardano.Kuber.Util (addrInEraToPkh, getDefaultSignKey, queryUtxos, skeyToAddr, skeyToAddrInEra, readSignKey)
import qualified Cardano.Ledger.Address as Shelley
import Cardano.Ledger.Crypto (StandardCrypto)
import Cardano.Marketplace.Common.ConsoleWritable (ConsoleWritable (toConsoleText))
import Cardano.Marketplace.V1.Core (buyToken, marketAddressShelley, marketScriptAddr, placeOnMarket, signAndSubmitTxBody)
import Cardano.Marketplace.V1.RequestModels
import Cardano.Marketplace.V1.ServerRuntimeContext (RuntimeContext (RuntimeContext), resolveContext)
import Control.Concurrent (MVar, forkIO, killThread, newMVar, putMVar, takeMVar, threadDelay, withMVar)
import Control.Concurrent.Async (forConcurrently, forConcurrently_, mapConcurrently, mapConcurrently_, withAsync)
import Control.Exception (SomeException, try)
import Control.Monad (foldM, forM, forM_)
import Control.Monad.Reader (MonadIO (liftIO), ReaderT (runReaderT))
import Control.Monad.State
import Criterion.Main
import Criterion.Main.Options
import Criterion.Types (Config (verbosity), Verbosity (Verbose))
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
import System.Environment (getArgs, getEnv)
import System.IO (BufferMode (NoBuffering), IOMode (ReadMode), hFlush, hGetContents, hSetBuffering, openFile)
import Text.Read (readMaybe)
import System.Directory (doesFileExist)
import System.Random (newStdGen)
import System.Random.Shuffle (shuffle')
import qualified Data.ByteString.Char8 as BS8

testTokensStr = "fe0f87df483710134f34045b516763bad1249307dfc543bc56a9e738.testtoken"

defaultNoOfWallets = 1

-- If CARDANO_NODE_SOCKET_PATH environment variable is set,  return ConnectInfo instance with the path
-- Otherwise CARDANO_HOME or "$HOME/.cardano"  is used and the socket path becomes "$CARDANO_HOME/node.socket"
getDefaultConnection :: String -> NetworkId ->  IO (LocalNodeConnectInfo CardanoMode)
getDefaultConnection networkName networkId= do
  sockEnv <- try $ getEnv "CARDANO_NODE_SOCKET_PATH"
  socketPath <-case  sockEnv of
    Left (e::IOError) -> do
          defaultSockPath<- getWorkPath ( if null networkName then ["node.socket"] else [networkName,"node.socket"])
          exists<-doesFileExist defaultSockPath
          if exists then return defaultSockPath else  error $ "Socket File is Missing: "++defaultSockPath ++"\n\tSet environment variable CARDANO_NODE_SOCKET_PATH  to use different path"
    Right s -> pure s
  pure (localNodeConnInfo networkId socketPath )

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
  -- performTransferBench noOfWallets

  if noOfWallets > 333
    then error "Currently max no of wallets supported are 333 since total used are 333 * 3 = 999"
    else do
      testAsset <- parseAssetIdText $ T.pack testTokensStr
      let network=Testnet  (NetworkMagic 9)
      conn <-getDefaultConnection  "testnet" network
      let connectInfo = ChainConnectInfo conn
      dcInfo <- withDetails connectInfo
      fundedSignKey <- readSignKey "/home/krunx/.cardano/default.skey"

      -- printUtxoOfWallet dcInfo fundedSignKey

      wallets <- setupWallets requiredWallets dcInfo testAsset fundedSignKey

      -- printUtxoOfWallets dcInfo wallets

      --Setup step for collatral until vasil collateral is used
      -- splitUtxosOfWallets dcInfo wallets

      rng <- newStdGen
      let shuffledWallets = shuffle' wallets (length wallets) rng
      performMarketBench dcInfo noOfWallets shuffledWallets testAsset fundedSignKey

      -- printUtxoOfWallets dcInfo shuffledWallets
      putStrLn "\nFinished..."


readWalletsFromFile  :: Int -> IO [SigningKey PaymentKey]
readWalletsFromFile noOfWallets = do
  readHandle <- openFile "1000-wallets.txt" ReadMode
  content <- hGetContents readHandle
  let linesOfFile = lines content
      walletStrs = take noOfWallets linesOfFile
  mapM parseSigningKey walletStrs


-- TODO Refactor and remove unused code
setupWallets :: Int -> DetailedChainInfo -> AssetId -> SigningKey PaymentKey -> IO [SigningKey PaymentKey]
setupWallets noOfWallets dcInfo testAssetId fundedSignKey = do
  wallets <- readWalletsFromFile noOfWallets
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
      forConcurrently_ loopArray $ \index -> do
        performMarketOperation dcInfo testAsset index market startTime walletsTuples atomicPutStrLn atomicPutStr fundedSignKey marketState marketAddrAny atomicQueryUtxos

      finishedTime <- getTimeInSec
      printDiffInSec "\nTime taken on performing whole market operation for all wallets" startTime finishedTime
      -- killThread tId

getWalletListOfIndex index (priSellers, priBuyers, secBuyers) = [priSellers !! index, priBuyers !! index, secBuyers !! index]

getSingleWallets index (priSellers, priBuyers, secBuyers) = (priSellers !! index, priBuyers !! index, secBuyers !! index)

-- Perform primary sell, primary buy, secondary sell and secondary buy with roaylty checking
performMarketOperation ::
  DetailedChainInfo ->
  AssetId ->
  Int ->
  Market ->
  Int64 ->
  ([SigningKey PaymentKey], [SigningKey PaymentKey], [SigningKey PaymentKey]) ->
  (String -> IO ()) ->
  (String -> IO ()) ->
  SigningKey PaymentKey ->
  MarketUTxOState ->
    AddressAny ->
  (AddressAny -> IO (UTxO BabbageEra)) ->
  IO ()
performMarketOperation dcInfo testAsset index market afterPaidTime walletTuples atomicPutStrLn atomicPutStr fundedSignKey marketState marketAddrAny atomicQueryUtxos = do
  let (priSeller, priBuyer, secBuyer) = getSingleWallets index walletTuples

  --Primary sell
  priSellTx <- loopedPerformPrimarySale priSeller
  -- performPrimarySale dcInfo testAsset market marketAddrAny priSeller index atomicPutStrLn atomicPutStr marketState atomicQueryUtxos
  afterPrimarySellTime <- getTimeInSec
  printDiffInSecAtomic ("\nTime taken on placing token to market for Wallet Set " ++ show index) afterPaidTime afterPrimarySellTime atomicPutStrLn

  --Primary buy
  priBuyTx <- loopedPerformBuy priSellTx priBuyer priSeller
  -- performBuy dcInfo testAsset market priSellTx priBuyer priSeller index atomicPutStrLn atomicPutStr "primary " atomicQueryUtxos marketState marketAddrAny
  afterPrimaryBuyTime <- getTimeInSec
  printDiffInSecAtomic ("\nTime taken on primary buying token from the market for Wallet Set " ++ show index) afterPrimarySellTime afterPrimaryBuyTime atomicPutStrLn

  --Seconday sell
  secSellTx <- loopedPerformSecondarySale priSeller priBuyer
  -- performSecondarySale dcInfo testAsset market marketAddrAny priBuyer priSeller index atomicPutStrLn atomicPutStr marketState atomicQueryUtxos
  afterSecondarySellTime <- getTimeInSec
  printDiffInSecAtomic ("\nTime taken on placing secondary token to the market for Wallet Set " ++ show index) afterPrimaryBuyTime afterSecondarySellTime atomicPutStrLn

  --Secondary buy
  secBuyTx <- loopedPerformBuy secSellTx secBuyer priBuyer
  -- performBuy dcInfo testAsset market secSellTx secBuyer priBuyer index atomicPutStrLn atomicPutStr "secondary " atomicQueryUtxos marketState marketAddrAny
  afterSecondaryBuyTime <- getTimeInSec
  printDiffInSecAtomic ("\nTime taken on secondary buy of token from the market for Wallet Set " ++ show index) afterSecondarySellTime afterSecondaryBuyTime atomicPutStrLn

  printDiffInSecAtomic ("\nTime taken for Wallet Set " ++ show index ++ " to complete market operation") afterPaidTime afterSecondaryBuyTime atomicPutStrLn

  --Checking roayalty received
  -- _ <- checkRoyalty dcInfo priSellTx secSellTx secBuyTx atomicPutStrLn
  atomicPutStrLn ("Finished performing market operations for Wallet Set " ++ show index)

  where
    loopedPerformPrimarySale  priSeller= do
      result <- try (performPrimarySale dcInfo testAsset market marketAddrAny priSeller index atomicPutStrLn atomicPutStr marketState atomicQueryUtxos) :: IO (Either SomeException (TxResponse, TxId, ScriptData))
      case result of
        Left any -> do
          print any
          loopedPerformPrimarySale priSeller
        Right res -> pure res

    loopedPerformSecondarySale  priSeller priBuyer= do
      result <- try (performSecondarySale dcInfo testAsset market marketAddrAny priBuyer priSeller index atomicPutStrLn atomicPutStr marketState atomicQueryUtxos) :: IO (Either SomeException (TxResponse, TxId, ScriptData))
      case result of
        Left any -> do
          print any
          loopedPerformSecondarySale priSeller priBuyer
        Right res -> pure res

    loopedPerformBuy  sellTx buyer prevSeller = do
      result <- try (
          performBuy dcInfo testAsset market sellTx buyer prevSeller index atomicPutStrLn atomicPutStr "primary " atomicQueryUtxos marketState marketAddrAny
        ) :: IO (Either SomeException (SigningKey PaymentKey, AddressAny, TxId))
      case result of
        Left any -> do
          print any
          loopedPerformBuy sellTx buyer prevSeller
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
  secSellTx@(_,txId,_) <- performSingleSale dcInfo testAsset True market secSeller [] secondaryCost index atomicPutStrLn atomicQueryUtxos

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
performSingleSale dcInfo testAsset isSecondary market sellerWallet sReqParties cost index atomicPutStrLn atomicQueryUtxos= do
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
  walletUtxos@(UTxO utxoMap) <- atomicQueryUtxos sellerAddrAny
  -- let firstUtxoHavingAdaOnly = UTxO $ fst $ Map.splitAt 1 $ Map.filter (\(TxOut _ (TxOutValue _ v) _ _) -> case valueToLovelace v of
  --       Just (Lovelace l) -> l > 0
  --       Nothing -> False) utxoMap
  -- print firstUtxoHavingAdaOnly

  directSaleDatum <- constructDirectSaleDatum sellerPkh model
  let lockedValue = valueFromList [(testAsset, 1),(AdaAssetId, 2_000_000)]
      txOperations = txPayToScript (marketScriptAddr dcInfo market) lockedValue (hashScriptData directSaleDatum)
                    <> txWalletAddress sellerAddrInEra
                    <> txConsumeUtxos walletUtxos

  txResponse@(TxResponse txRaw datums) <- loopedSellIfFail txOperations
  -- placeOnMarket' dcInfo txOperation sellerWallet
  let txId = txIdFromTxResponse txResponse
  -- placeOnMarket dcInfo market model
  atomicPutStrLn $ "Submitted Tx Id : " ++ show txId ++ "for Wallet Set " ++ show index
  return (txResponse, txId, directSaleDatum)
  where
    --TODO better exception handling currently it loops for all failed
    loopedSellIfFail txOperations = do
      result <- try (placeOnMarket' dcInfo txOperations sellerWallet) :: IO (Either SomeException TxResponse)
      case result of
        Left any -> do
          print any
          loopedSellIfFail txOperations
        Right res -> pure res

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
performBuy dcInfo testAsset market (_,sellTxId, datum) buyerWallet prevSellerWallet index atomicPutStrLn atomicPutStr buyType atomicQueryUtxos marketState marketAddrAny= do
  --Perform Primary buy of the token from another set of wallets
  atomicPutStrLn ("\nPerforming " ++ buyType ++ " buy for Wallet Set " ++ show index)

  buyTx@(_, addr, txId) <- loopedBuyIfFail
  -- performSingleBuy dcInfo buyerWallet testAsset datum artaConfig market

  putStrLn $ "\nSubmitted successfully TxHash " ++ show txId
  --Wait for transaction to appear on buyers wallet
  atomicPutStrLn ("\nWait for bought token to appear on " ++ buyType ++ " buyer wallet. For Wallet Set " ++ show index)
  pollForTxId' dcInfo addr txId atomicPutStrLn atomicQueryUtxos

  -- watchMarketForTxIdDisappear dcInfo sellTxId index atomicPutStrLn atomicPutStr marketState "Primary Sell "


  --TODO check for wallet valule with priting sellers and buyers wallet values
  -- printUtxoOfWalletAtomic dcInfo buyerWallet index atomicPutStrLn
  -- printUtxoOfWalletAtomic dcInfo prevSellerWallet index atomicPutStrLn

  return buyTx
  where
    --TODO better exception handling currently it loops for all failed
    loopedBuyIfFail = do
      result <- try (performSingleBuy dcInfo buyerWallet testAsset sellTxId datum market) :: IO (Either SomeException (SigningKey PaymentKey, AddressAny, TxId))
      case result of
        Left any -> do
          print any
          loopedBuyIfFail
        Right tuple -> pure tuple

-- Perfrom single buy from single wallet
performSingleBuy ::
  DetailedChainInfo ->
  SigningKey PaymentKey ->
  AssetId ->
  TxId ->
  ScriptData ->
  Market ->
  IO (SigningKey PaymentKey, AddressAny, TxId)
performSingleBuy dcInfo buyerWallet tokenAsset sellTxId datum market = do
  let buyerAddr = getAddrEraFromSignKey dcInfo buyerWallet
      buyModel = BuyReqModel (TxContextAddressesReq (Just buyerWallet) Nothing Nothing Nothing Nothing Map.empty) Nothing (Just $ UtxoIdModal (sellTxId, TxIx 0)) (Just tokenAsset) datum Nothing
  txRes <- buyToken dcInfo market buyModel buyerAddr
  let buyerAddrAny = getAddrAnyFromEra buyerAddr
      txId = txIdFromTxResponse txRes
  return (buyerWallet, buyerAddrAny, txId)

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
