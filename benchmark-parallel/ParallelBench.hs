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
    AlonzoEra,
    AsType (AsAddressAny, AsAddressInEra, AsAlonzoEra, AsPaymentKey, AsSigningKey),
    AssetId (AdaAssetId, AssetId),
    CardanoEra (AlonzoEra),
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
    valueToList, hashScriptData, TxIx (TxIx), NetworkId (Testnet), LocalNodeConnectInfo, CardanoMode, NetworkMagic (NetworkMagic), prettyPrintJSON
  )
import Cardano.Api.Shelley (Address (ShelleyAddress), Lovelace (Lovelace), Quantity (Quantity), fromPlutusData, toShelleyAddr)
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers (parseAssetId, parseAssetIdText, parseAssetNQuantity, parseScriptData)
import Cardano.Kuber.Util (addrInEraToPkh, getDefaultSignKey, queryUtxos, skeyToAddr, skeyToAddrInEra)
import qualified Cardano.Ledger.Address as Shelley
import Cardano.Ledger.Crypto (StandardCrypto)
import Cardano.Marketplace.Common.ConsoleWritable (ConsoleWritable (toConsoleText))
import Cardano.Marketplace.V1.Core (buyToken, marketAddressShelley, marketScriptAddr, placeOnMarket)
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
import Data.Maybe (fromJust, fromMaybe, isJust)
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


testTokensStr = "d81081613c3d56c732f9364a55eeaf55ae3eedd7bd5d338e64f5a115.testtoken"

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
      let network=Testnet  (NetworkMagic 1097911063)
      conn <-getDefaultConnection  "testnet" network
      let ctx = ChainConnectInfo conn
      fundedSignKey <- getDefaultSignKey
      wallets <- setupWallets requiredWallets ctx testAsset fundedSignKey
      
      -- splitUtxosOfWallets ctx wallets
      
      rng <- newStdGen
      let shuffledWallets = shuffle' wallets (length wallets) rng
      performMarketBench noOfWallets shuffledWallets testAsset fundedSignKey

      -- printUtxoOfWallets ctx wallets
      putStrLn "\nFinished..."

-- TODO Refactor and remove unused code
setupWallets :: ChainInfo v => Int -> v -> AssetId -> SigningKey PaymentKey -> IO [SigningKey PaymentKey]
setupWallets noOfWallets ctx testAssetId fundedSignKey = do
  readHandle <- openFile "1000-wallets.txt" ReadMode
  content <- hGetContents readHandle
  let linesOfFile = lines content
  let walletStrs = take noOfWallets linesOfFile
  wallets <- mapM parseSigningKey walletStrs
  let walletsAddrs = map (\s -> AddressShelley $ skeyToAddr s (getNetworkId ctx)) wallets
  utxosE <- queryUtxos (getConnectInfo ctx) $ Set.fromList walletsAddrs
  utxos@(UTxO utxoMap) <- case utxosE of
    Left err -> error $ "Error getting utxos: " ++ show err
    Right utxos -> return utxos
  let utxoList = Map.toList utxoMap
      addrValueMap =
        foldl
          ( \mp utxo@(_, TxOut aie (TxOutValue _ v) _) ->
              let addr = toShelleyAddr aie
               in case Map.lookup addr mp of
                    Nothing -> Map.insert addr v mp
                    Just a -> Map.insert addr (a <> v) mp
          )
          Map.empty
          utxoList

      balancesWithLess = Map.filter (\v -> not $ v `valueGte` valueFromList [(AdaAssetId, Quantity 20_000_000), (testAssetId, Quantity 10)]) addrValueMap
      balancesWithLessAddrs = map (\(Shelley.Addr nw pc scr, _) -> shelleyAddressInEra $ ShelleyAddress nw pc scr) $ Map.toList balancesWithLess

  if not (null balancesWithLessAddrs)
    then do
      putStrLn "Wallets with not enough value in them\n"
      pPrint balancesWithLess
       --TODO Already split the utxo into chunks of main wallet
      let walletAddrsChunks = chunksOf 100 balancesWithLessAddrs
      mapM_
        ( \walletChunk -> do
            putStrLn $ "Funding wallet chunk " ++ show (length walletChunk)
            -- fundWallets ctx walletChunk fundedSignKey
            fundWalletsWithAdaOnly ctx walletChunk fundedSignKey
        )
        walletAddrsChunks
      print "Wallet funding completed."
    else print "All wallets have enough value."
 
  pure wallets

  where
    fundWallets :: ChainInfo v => v -> [AddressInEra AlonzoEra] -> SigningKey PaymentKey -> IO ()
    fundWallets ctx walletAddrs fundedSignKey = do
      let fundAddr = getAddrEraFromSignKey ctx fundedSignKey
          utxoValue = valueFromList [(AdaAssetId, Quantity 100_000_000), (testAssetId, Quantity 100)]
          addressesWithValue = map (,utxoValue) walletAddrs
          tokenAnd100AdaPayOperation = foldMap (uncurry txPayTo) addressesWithValue
          txOperations = tokenAnd100AdaPayOperation <> txWalletAddress fundAddr
      txBodyE <- txBuilderToTxBodyIO ctx txOperations
      txBody <- case txBodyE of
        Left err -> error $ "Error building tx: " ++ show err
        Right txBody -> return txBody
      tx <- signAndSubmitTxBody (getConnectInfo ctx) txBody [fundedSignKey]
      let txHash = getTxId $ getTxBody tx

      putStrLn $ "\nSubmitted successfully TxHash " ++ show txHash

      --Wait for single transaction to complete
      let firstAddrAny = getAddrAnyFromEra $ fst $ head addressesWithValue
      putStrLn "Wait for funds to appear on wallet."
      pollForTxId ctx firstAddrAny txHash

    fundWalletsWithAdaOnly :: ChainInfo v => v -> [AddressInEra AlonzoEra] -> SigningKey PaymentKey -> IO ()
    fundWalletsWithAdaOnly ctx walletAddrs fundedSignKey = do
      let fundAddr = getAddrEraFromSignKey ctx fundedSignKey
          utxoValue = valueFromList [(AdaAssetId, Quantity 100_000_000)]
          addressesWithValue = map (,utxoValue) walletAddrs
          tokenAnd100AdaPayOperation = foldMap (uncurry txPayTo) addressesWithValue
          txOperations = tokenAnd100AdaPayOperation <> txWalletAddress fundAddr
      txBodyE <- txBuilderToTxBodyIO ctx txOperations
      txBody <- case txBodyE of
        Left err -> error $ "Error building tx: " ++ show err
        Right txBody -> return txBody
      tx <- signAndSubmitTxBody (getConnectInfo ctx) txBody [fundedSignKey]
      let txHash = getTxId $ getTxBody tx

      putStrLn $ "\nSubmitted successfully TxHash " ++ show txHash

      --Wait for single transaction to complete
      let firstAddrAny = getAddrAnyFromEra $ fst $ head addressesWithValue
      putStrLn "Wait for funds to appear on wallet."
      pollForTxId ctx firstAddrAny txHash


performMarketBench :: Int -> [SigningKey PaymentKey] -> AssetId -> SigningKey PaymentKey -> IO ()
performMarketBench noOfWallets wallets testAsset fundedSignKey = do
  eCtx <- resolveContext
  case eCtx of
    Left error -> putStrLn $ "RuntimeConfigurationError:\n - " ++ show error
    Right (RuntimeContext ctx market _ _ _ _) -> do
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
                  utxosE <- queryUtxos (getConnectInfo ctx) $ Set.singleton addrAny
                  case utxosE of
                    Left err -> error $ "Error getting utxos: " ++ show err
                    Right utxos -> return utxos
              )

      let atomicQueryNetwork v = withMVar queryLock (\_ -> withDetails v)

      -- Spawn new thread for querying market utxos
      marketState <- newMarketState
      let marketAddress = marketAddressShelley market (getNetworkId ctx)
      let marketAddrAny = getAddrAnyFromEra marketAddress
      tId <- forkIO $ pollMarketUtxos ctx marketAddrAny marketState atomicQueryUtxos atomicPutStrLn

      -- Perform market operations parrallely for each set of seller and buyers wallet indepdently and at last payback to funded wallet
      forConcurrently_ loopArray $ \index -> do
        performMarketOperation ctx testAsset index market startTime walletsTuples atomicPutStrLn atomicPutStr fundedSignKey marketState atomicQueryUtxos atomicQueryNetwork

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
  (AddressAny -> IO (UTxO AlonzoEra)) ->
  (DetailedChainInfo -> IO DetailedChainInfo) ->
  IO ()
performMarketOperation ctx testAsset index market afterPaidTime walletTuples atomicPutStrLn atomicPutStr fundedSignKey marketState atomicQueryUtxos atomicQueryNetwork = do
  let (priSeller, priBuyer, secBuyer) = getSingleWallets index walletTuples

  --Primary sell
  priSellTx <- performPrimarySale ctx testAsset market priSeller index atomicPutStrLn atomicPutStr marketState atomicQueryNetwork
  afterPrimarySellTime <- getTimeInSec
  printDiffInSecAtomic ("\nTime taken on placing token to market for Wallet Set " ++ show index) afterPaidTime afterPrimarySellTime atomicPutStrLn

  --Primary buy
  priBuyTx <- performBuy ctx testAsset market priSellTx priBuyer priSeller index atomicPutStrLn atomicPutStr "primary " atomicQueryUtxos atomicQueryNetwork
  afterPrimaryBuyTime <- getTimeInSec
  printDiffInSecAtomic ("\nTime taken on primary buying token from the market for Wallet Set " ++ show index) afterPrimarySellTime afterPrimaryBuyTime atomicPutStrLn

  --Seconday sell
  secSellTx <- performSecondarySale ctx testAsset market priBuyer priSeller index atomicPutStrLn atomicPutStr marketState atomicQueryNetwork
  afterSecondarySellTime <- getTimeInSec
  printDiffInSecAtomic ("\nTime taken on placing secondary token to the market for Wallet Set " ++ show index) afterPrimaryBuyTime afterSecondarySellTime atomicPutStrLn

  --Secondary buy
  secBuyTx <- performBuy ctx testAsset market secSellTx secBuyer priBuyer index atomicPutStrLn atomicPutStr "secondary " atomicQueryUtxos atomicQueryNetwork
  afterSecondaryBuyTime <- getTimeInSec
  printDiffInSecAtomic ("\nTime taken on secondary buy of token from the market for Wallet Set " ++ show index) afterSecondarySellTime afterSecondaryBuyTime atomicPutStrLn

  printDiffInSecAtomic ("\nTime taken for Wallet Set " ++ show index ++ " to complete market operation") afterPaidTime afterSecondaryBuyTime atomicPutStrLn

  --Checking roayalty received
  -- _ <- checkRoyalty ctx priSellTx secSellTx secBuyTx atomicPutStrLn
  atomicPutStrLn ("Finished performing market operations for Wallet Set " ++ show index)

-- Perform primary sell from primary seller set of wallets
performPrimarySale ctx testAsset market priSellerWallet index atomicPutStrLn atomicPutStr marketState atomicQueryNetwork = do
  let primaryCost = (AdaAssetId, Quantity 2_000_000)

  --Direct sell from all wallet without waiting
  atomicPutStrLn ("\nPerforming primary sell from wallet Set " ++ show index)
  priSellTx@(_, txId, _) <- performSingleSale ctx testAsset False market priSellerWallet [] primaryCost index atomicPutStrLn

  --Now watch for market for tx id to appear in market address
  atomicPutStrLn ("\nWait for primary sell transaction to appear on market address for Wallet Set " ++ show index)

  watchMarketForTxId txId index atomicPutStrLn atomicPutStr marketState

  --TODO check if values are deducted on wallet with printing it
  -- printUtxoOfWalletAtomic ctx priSellerWallet index atomicPutStrLn

  return priSellTx

-- Perfrom secondary sale from placing royalty party as primary sellers
performSecondarySale ctx testAsset market secSeller priSeller index atomicPutStrLn atomicPutStr marketState atomicQueryNetwork = do
  --Perform secondary sell from buyers wallet without waiting
  atomicPutStrLn ("\nPerform secondary sell from previouos buyer wallet using roalty parties as previous primary seller for Wallet " ++ show index)
  let roaltyPercentToReqParty = 50_000_000
      primarySellerAddr = skeyToAddrInEra priSeller (getNetworkId ctx)
      secondaryCost = (AdaAssetId, Quantity 2_000_000)
  secSellTx@(_,txId,_) <- performSingleSale ctx testAsset True market secSeller [] secondaryCost index atomicPutStrLn

  --Waiting for transaction completion
  atomicPutStrLn ("\nWait for secondary sell transaction to appear on market address for Wallet Set " ++ show index)
  watchMarketForTxId txId index atomicPutStrLn atomicPutStr marketState
  return secSellTx

-- Perfrom single sale of placing token in the market from single seller wallet
performSingleSale ::
  ChainInfo v =>
  v ->
  AssetId ->
  Bool ->
  Market ->
  SigningKey PaymentKey ->
  [ShareModal] ->
  (AssetId, Quantity) ->
  Int ->
  ([Char] -> IO a3) ->
  IO (TxResponse, TxId, ScriptData)
performSingleSale ctx testAsset isSecondary market sellerWallet sReqParties cost index atomicPutStrLn = do
  let model =
        SellReqModel
          { sreqParties = sReqParties,
            sreqAsset = CostModal (testAsset, 1),
            sreqCost = CostModal cost,
            isSecondary = isSecondary
          }
  let sellerAddrInEra = skeyToAddrInEra sellerWallet (getNetworkId ctx)
  sellerPkh <- addrInEraToPkh sellerAddrInEra

  directSaleDatum <- constructDirectSaleDatum sellerPkh model
  let lockedValue = valueFromList [(testAsset, 1),(AdaAssetId, 2_000_000)]
      txOperations = txPayToScript (marketScriptAddr ctx market) lockedValue (hashScriptData directSaleDatum)
                    <> txWalletAddress sellerAddrInEra

  txResponse@(TxResponse txRaw datums) <- loopedSellIfFail txOperations
  -- placeOnMarket' ctx txOperation sellerWallet
  let txId = txIdFromTxResponse txResponse
  -- placeOnMarket ctx market model
  atomicPutStrLn $ "Submitted Tx Id : " ++ show txId ++ "for Wallet Set " ++ show index
  return (txResponse, txId, directSaleDatum)
  where
    --TODO better exception handling currently it loops for all failed
    loopedSellIfFail txOperations = do
      result <- try (placeOnMarket' ctx txOperations sellerWallet) :: IO (Either SomeException TxResponse)
      case result of
        Left any -> do
          print any
          loopedSellIfFail txOperations
        Right res -> pure res

placeOnMarket' :: ChainInfo v => v -> TxBuilder -> SigningKey PaymentKey -> IO TxResponse
placeOnMarket' ctx txOperations wallet = do
  -- putStrLn $ BS8.unpack $ prettyPrintJSON txOperations
  txBodyE <- txBuilderToTxBodyIO ctx txOperations
  txBody <- case txBodyE of
    Left err -> error $ "Error in creating transaction " ++ show err
    Right txBody -> return txBody
  tx <- signAndSubmitTxBody (getConnectInfo ctx) txBody [wallet]
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
performBuy ctx testAsset market (_,sellTxId, datum) buyerWallet prevSellerWallet index atomicPutStrLn atomicPutStr buyType atomicQueryUtxos atomicQueryNetwork = do
  --Perform Primary buy of the token from another set of wallets
  atomicPutStrLn ("\nPerforming " ++ buyType ++ " buy for Wallet Set " ++ show index)

  buyTx@(_, addr, txId) <- loopedBuyIfFail
  -- performSingleBuy ctx buyerWallet testAsset datum artaConfig market

  putStrLn $ "\nSubmitted successfully TxHash " ++ show txId
  --Wait for transaction to appear on buyers wallet
  atomicPutStrLn ("\nWait for bought token to appear on " ++ buyType ++ " buyer wallet. For Wallet Set " ++ show index)
  pollForTxId' ctx addr txId atomicPutStrLn atomicQueryUtxos

  --TODO check for wallet valule with priting sellers and buyers wallet values
  -- printUtxoOfWalletAtomic ctx buyerWallet index atomicPutStrLn
  -- printUtxoOfWalletAtomic ctx prevSellerWallet index atomicPutStrLn

  return buyTx
  where
    --TODO better exception handling currently it loops for all failed
    loopedBuyIfFail = do
      result <- try (performSingleBuy ctx buyerWallet testAsset sellTxId datum market atomicQueryUtxos atomicQueryNetwork) :: IO (Either SomeException (SigningKey PaymentKey, AddressAny, TxId))
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
  (AddressAny -> IO (UTxO AlonzoEra)) ->
  (v -> IO DetailedChainInfo) ->
  IO (SigningKey PaymentKey, AddressAny, TxId)
performSingleBuy dcInfo buyerWallet tokenAsset sellTxId datum market atomicQueryUtxos atomicQueryNetwork = do
  let buyerAddr = getAddrEraFromSignKey dcInfo buyerWallet
      buyModel = BuyReqModel (TxContextAddressesReq (Just buyerWallet) Nothing Nothing Nothing Nothing Map.empty) Nothing (Just $ UtxoIdModal (sellTxId, TxIx 0)) (Just tokenAsset) datum Nothing

  txRes <- buyToken dcInfo market buyModel buyerAddr
  let buyerAddrAny = getAddrAnyFromEra buyerAddr
      txId = txIdFromTxResponse txRes
  return (buyerWallet, buyerAddrAny, txId)

txIdFromTxResponse :: TxResponse -> TxId
txIdFromTxResponse (TxResponse tx _) = getTxId $ getTxBody tx
-- -- TODO Check royalty recevied or not for primary seller wallet that is placed as party when placing secondary sell
-- checkRoyalty ctx priSellTx secSellTx secBuyTx atomicPutStrLn = do
--     atomicPutStrLn "\nCheck for royalty recevied to roalty party sepecifed from secondary sell or not"

--     -- -- forM_ loopArray $ \index -> do
--     -- --     let (roaltyParty,_,_,_) = priSellTxs !! index
--     -- --     let (_,(_,Quantity secnondarySellCost),_,_) = secSellTxs !! index
--     -- --     let (secBuyer,secBuyerAddress,secBuyTxId) = secBuyTxs !! index

--     -- --     let totalValueAfterPlatformCut = secnondarySellCost - ((secnondarySellCost * 2_500_000) `divide` marketHundredPercent)
--     -- --     let valueForSreqParty = (totalValueAfterPlatformCut * roaltyPercentToReqParty) `divide` marketHundredPercent

--     -- --     let checkValue = valueFromList [(AdaAssetId , Quantity valueForSreqParty)]
--     -- --     roaltyPartyAddrAny <- getAddrAnyFromSignKey roaltyParty
--     -- --     pollForTxIdAndValueAtomic ctx roaltyPartyAddrAny secBuyTxId checkValue

-- performTransferBench :: Int -> IO ()
-- performTransferBench noOfWallets = do
--   ctx <- chainInfoTestnet
--   fundedSignKey <- getDefaultSignKey
--   let loopArray = [0 .. (noOfWallets -1)]
--   wallets <- forM loopArray $ \_ -> generateSigningKey AsPaymentKey

--   let utxoValue = valueFromList [(AdaAssetId, Quantity 4_000_000)]
--       walletsWithValue = map (,utxoValue) wallets
--       addressesWithValue = map (\(wallet, value) -> (skeyToAddrInEra wallet (getNetworkId ctx), value)) walletsWithValue
--       txOperation = foldMap (uncurry txPayTo) addressesWithValue
--       fundedAddr = getAddrEraFromSignKey ctx fundedSignKey

--   txBodyE <- txBuilderToTxBodyIO ctx txOperation
--   txBody <- case txBodyE of
--     Left err -> error $ "Error building tx: " ++ show err
--     Right txBody -> return txBody
--   tx <- signAndSubmitTxBody (getConnectInfo ctx) txBody [fundedSignKey]
--   let txHash = getTxId $ getTxBody tx


--   putStrLn $ "\nSubmitted successfully TxHash " ++ show txHash

--   --Wait for single transaction to complete
--   let firstAddrAny = getAddrAnyFromEra $ fst $ head addressesWithValue
--   putStrLn "Wait for funds to appear on wallet."
--   pollForTxId ctx firstAddrAny txHash

--   printLock <- newMVar ()
--   let atomicPutStrLn str = withMVar printLock (\_ -> putStrLn str)

--   queryLock <- newMVar ()
--   let atomicQueryUtxos addrAny = withMVar queryLock (\_ -> queryUtxos (getConnectInfo ctx) $ Set.singleton addrAny)

--   -- forConcurrently_ loopArray $ \index -> do
--   --Payback to funded wallet from all wallets and wait for transaction to complete

--   --Print utxos of all wallets
--   putStrLn "\nNow print funds available on all wallets."
--   printUtxoOfWallets ctx wallets

--   forConcurrently_ loopArray $ \index -> do
--     let wallet = wallets !! index
--     paybackToFundedWallet' ctx wallet index fundedSignKey atomicPutStrLn atomicQueryUtxos

--   -- mapConcurrently_ (\wallet-> paybackToFundedWallet' ctx wallet 0 fundedSignKey atomicPutStrLn atomicQueryUtxos) wallets

--   --Print utxos of funded wallet
--   putStrLn "Funds available on funding wallet after transferring to all wallets"
--   printUtxoOfWallet ctx fundedSignKey

--   -- Merger all utxos of funded wallet at last
--   mergeAllUtxos ctx fundedSignKey

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
