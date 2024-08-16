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
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers (parseAssetNQuantity, parseScriptData)
import Cardano.Kuber.Util
import qualified Cardano.Ledger.Address as Shelley

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
import GHC.Conc (atomically, newTVar, newTVarIO, readTVar, writeTVar, readTVarIO)
import GHC.IO.Handle.FD (stdout)
import GHC.Int (Int64)
import PlutusTx (toData)
import PlutusTx.Prelude (divide)
import Data.Time ( UTCTime, getCurrentTime )
import System.Environment (getArgs)
import System.IO (BufferMode (NoBuffering), hFlush, hSetBuffering)
import System.Random (randomRIO)
import Text.Read (readMaybe)
import qualified Data.ByteString.Char8 as BS8
import Control.Concurrent.Async (forConcurrently_)
import Cardano.Ledger.Coin
import Cardano.Marketplace.SimpleMarketplace (SimpleMarketHelper(..))
import Cardano.Marketplace.Common.TransactionUtils (getTxIdFromTx)
import qualified GHC.Conc as Control
import PlutusLedgerApi.V1 (POSIXTime (getPOSIXTime))
import Data.Aeson ( ToJSON(toJSON) )
import qualified Data.Aeson as A
import Cardano.Kuber.Data.Models (TxModal(TxModal))
import Cardano.Kuber.Console.ConsoleWritable (toConsoleText)
import Data.Time.Clock (diffUTCTime)
import GHC.Base (when)
import Wallet (ShelleyWallet(..))
import Cardano.Kuber.Api (FrameworkError)
import qualified Debug.Trace as Debug

data TransactionTime = TransactionTime {
    ttTxName :: String
  , ttTx :: Either FrameworkError (Tx ConwayEra)
  , ttStartTime :: UTCTime
  , ttEndTime :: UTCTime
} deriving (Show)

data BenchRun =BenchRun {
    brId :: Integer
  , brStartTime :: UTCTime
  , brEndTime :: UTCTime
  , brTimings :: [TransactionTime]
} deriving (Show)

instance ToJSON TransactionTime where
  toJSON (TransactionTime txName eTx startTime endTime) = A.object [
        "name" A..=  txName
      , case eTx of
        Left e ->  "error"  A..=  e
        Right tx ->  "tx"  A..=  TxModal ( InAnyCardanoEra ConwayEra tx)
      , "startTime" A..= startTime
      , "endTime" A..= endTime
    ]

instance FromJSON TransactionTime where
  parseJSON (A.Object v) = do
      fmError<- v A..:? "error"
      eTx <- case fmError of
        Nothing ->  do
          (TxModal (InAnyCardanoEra ConwayEra tx))<- v A..: "tx"
          pure $ Right tx
        Just e -> pure $ Left e

      TransactionTime <$>
            (v A..: "name")
          <*> pure eTx
          <*> (v A..: "startTime")
          <*> (v A..: "endTime")
  parseJSON _ = fail "Expected Transaction Time Object got something else"

instance ToJSON BenchRun where
  toJSON (BenchRun id startTime endTime timings) = A.object [
        "id" A..= id
      , "startTime" A..= startTime
      , "endTime" A..= endTime
      , "actions" A..= timings
    ]
    where

instance FromJSON BenchRun where
  parseJSON (A.Object v) = do
    BenchRun
      <$> (v A..: "id")
      <*> (v A..: "startTime")
      <*> (v A..: "endTime")
      <*> (v A..: "actions")

  parseJSON _ = fail "Expected BenchRun Object got something else"

monitoredSubmitTx' ::(HasKuberAPI api, HasSubmitApi api, HasChainQueryAPI api) =>Integer -> String ->   Kontract api w FrameworkError TxBuilder ->  Kontract api w FrameworkError TransactionTime
monitoredSubmitTx'  index txName  txBuilder = do
  startTime <- liftIO getCurrentTime
  catchError ( do 
      builder <- loopedAction True "setup" txBuilder
      tx <- loopedAction True  "buildAndSubmit" $  do
          tx <- kBuildTx builder
          kSubmitTx (InAnyCardanoEra ConwayEra tx)
          pure tx
      loopedWaitTxConfirmation tx
      endTime <- liftIO getCurrentTime
      pure $ TransactionTime txName (Right tx) startTime endTime
    ) (\e -> do 
        endTime <- liftIO getCurrentTime
        pure $ TransactionTime txName (Left e) startTime endTime
      )
  where
    loopedAction :: Bool ->  String ->  Kontract api w FrameworkError a -> Kontract api w FrameworkError a
    loopedAction shouldLog  actName action = do
      catchError (do
          result <- action
          when shouldLog
            $ liftIO $ putStrLn $ show index ++ " : " ++ txName ++ ": " ++ actName ++ " = " ++ "Finalied"
          pure result
        )
          (\e@(FrameworkError eType msg) -> case eType of
          ConnectionError  ->do -- connection errors will be retried
            liftIO $ do
              putStrLn $ show index ++ " : " ++ txName ++ "-" ++ actName ++ " : " ++  show e
              threadDelay 2_000_000
            loopedAction  shouldLog actName action
          _ -> throwError e
        )

    loopedWaitTxConfirmation tx =  loopedWaitTxIdConfirmation (getTxId$ getTxBody tx) 600
    loopedWaitTxIdConfirmation txId totalWaitSecs  =
          waitTxId txId  (totalWaitSecs * 1_000_000)
        where
          waitTxId txId remainingSecs =
            if remainingSecs < 0
              then kError TxSubmissionError $ "Transaction not confirmed after  " ++ show totalWaitSecs ++ " secs"
              else do
                startTime <- liftIO getCurrentTime
                (UTxO uMap):: UTxO ConwayEra <- loopedAction False "waitTxConfirmation" $ kQueryUtxoByTxin $  Set.singleton (TxIn txId (TxIx 0))
                liftIO $ Control.threadDelay 2_000_000
                endTime <- liftIO getCurrentTime
                case Map.toList uMap of
                  [] -> waitTxId txId (remainingSecs - (floor $ diffUTCTime startTime endTime * 1_000_000))
                  _ -> liftIO $ putStrLn $ show index ++ " : " ++ txName ++ "-" ++ "confirmation" ++ " : Confirmed " ++ show txId



monitoredSubmitTx ::(HasKuberAPI api, HasSubmitApi api, HasChainQueryAPI api) =>Integer -> String ->ShelleyWallet->   Kontract api w FrameworkError TxBuilder ->  Kontract api w FrameworkError TransactionTime
monitoredSubmitTx  index txName wallet  txBuilder =
  monitoredSubmitTx' index txName (do
     builder <- txBuilder
     pure$ builder <> txWalletSignKey (wPaymentSkey wallet) <> txWalletAddress (wAddress wallet)
  )


runOperations ::  (HasChainQueryAPI api, HasKuberAPI api, HasSubmitApi api) =>
  Integer -> TxIn -> SimpleMarketHelper api w ->  AssetId -> (ShelleyWallet,ShelleyWallet) ->
  Kontract api w FrameworkError BenchRun
runOperations index refScriptUtxo  marketHelper  sellAsset (sellerWallet,buyerWallet) = do
  startTime <- liftIO getCurrentTime

  netId <- kGetNetworkId
  let marketAddrInEra =  plutusScriptAddr  (simpleMarketScript marketHelper) netId
  let primarySaleBuilder = (sell marketHelper) marketAddrInEra (valueFromList [(sellAsset,1)] ) 2_000_000 (wAddress sellerWallet)
  results <- liftIO $ newTVarIO [ ]
  let recordAndGetTxId t = do
        liftIO $ atomically $ do 
            existing <- readTVar results
            writeTVar results (existing ++ [t])
        case  ttTx t of 
          Right v ->
              pure $ getTxId $ getTxBody  v
          Left e -> KError e

  let extractResults = liftIO $  do 
        endTime <- liftIO getCurrentTime
        resultList<-readTVarIO results
        pure $ BenchRun index  startTime endTime resultList
  -- perform primary sale.
  catchError ( do 
      primarySale  <- monitoredSubmitTx index "Primary Sale" sellerWallet
            $ primarySaleBuilder
      saleTxId <- recordAndGetTxId primarySale

      --  perform buy
      primaryBuy <- monitoredSubmitTx  index "Primary Buy" buyerWallet
            $  (buyWithRefScript marketHelper) (TxIn saleTxId (TxIx 0)) refScriptUtxo 
      recordAndGetTxId primaryBuy

      -- perform secondary sale
      secondarySale <- monitoredSubmitTx index "Secondary Sale"  buyerWallet
            $  (sell marketHelper) marketAddrInEra (valueFromList [(sellAsset,1)] ) 2_000_000 (wAddress buyerWallet)
      secondarySaleTxId <- recordAndGetTxId secondarySale

      -- perform withdraw
      withdraw <- monitoredSubmitTx index "Withdraw" buyerWallet
            $ (withdrawWithRefScript marketHelper) (TxIn secondarySaleTxId (TxIx 0)) refScriptUtxo
      recordAndGetTxId withdraw
      extractResults
    )
    (\e -> do
      extractResults
      )

    

runBuildAndSubmit :: (HasKuberAPI api, HasSubmitApi api) => TxBuilder -> Kontract api w FrameworkError (Tx ConwayEra)
runBuildAndSubmit txBuilder =  do
        tx<- kBuildTx txBuilder
        kSubmitTx (InAnyCardanoEra ConwayEra tx)
        liftIO $ putStrLn $ "Tx Submitted :" ++  (getTxIdFromTx tx)
        pure tx

waitTxIdConfirmation :: HasChainQueryAPI a => TxId -> Integer
      -> Kontract a w FrameworkError ()
waitTxIdConfirmation txId totalWaitSecs =
    waitTxId txId  totalWaitSecs
  where
    waitTxId txId remainingSecs =
      if remainingSecs < 0
        then kError TxSubmissionError $ "Transaction not confirmed after  " ++ show totalWaitSecs ++ " secs"
        else do
          (UTxO uMap):: UTxO ConwayEra <- kQueryUtxoByTxin $  Set.singleton (TxIn txId (TxIx 0))
          liftIO $ Control.threadDelay 2_000_000
          case Map.toList uMap of
            [] -> waitTxId txId (remainingSecs - 2)
            _ -> pure ()


waitTxConfirmation :: HasChainQueryAPI a => Tx ConwayEra -> Integer
      -> Kontract a w FrameworkError ()
waitTxConfirmation tx  =  waitTxIdConfirmation (getTxId$ getTxBody tx)
