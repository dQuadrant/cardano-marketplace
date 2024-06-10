{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Test.TestStorySimpleMarket where

import Test.Hspec ( before, describe, it, shouldBe, shouldSatisfy, expectationFailure, sequential )
import Test.Hspec.JUnit (hspecJUnit)
import Control.Monad.IO.Class (liftIO)
import Cardano.Kuber.Api (chainInfoFromEnv, evaluateKontract, HasChainQueryAPI (kGetNetworkId, kQueryUtxoByTxin, kQueryUtxoByAddress), throwFrameworkError, txWalletSignKey, txWalletAddress, Kontract, FrameworkError, kError, ErrorType (TxSubmissionError), TxBuilder, HasKuberAPI, HasSubmitApi)
import System.Environment.Blank (getEnvDefault)
import Cardano.Kuber.Data.Parsers
import qualified Data.Text as T
import System.Environment (getEnv)
import Cardano.Marketplace.Common.TransactionUtils
import Cardano.Marketplace.V2.Core (sellBuilder)
import Cardano.Marketplace.V2.Core
import Cardano.Api (Key(getVerificationKey), AssetName (AssetName), getTxId, getTxBody, TxIn (TxIn), UTxO (UTxO), ConwayEra, Tx, valueFromList, SerialiseAddress (serialiseAddress), toAddressAny, prettyPrintJSON)
import qualified Data.ByteString.Char8 as BS8
import qualified Data.Set as Set
import Cardano.Api.Shelley (TxIx(..), Tx (ShelleyTx))
import qualified Data.Map as Map
import qualified Control.Concurrent as Control
import GHC.Conc (newTVarIO, writeTVar, atomically, readTVarIO)
import Cardano.Kuber.Util (addressInEraToAddressAny, utxoSum)
import Cardano.Kuber.Console.ConsoleWritable (ConsoleWritable(toConsoleText, toConsoleTextNoPrefix))
import qualified Cardano.Ledger.Shelley.Core as L
import Control.Lens ((^.))
import qualified Cardano.Ledger.Alonzo.TxWits as L
import qualified Cardano.Ledger.Alonzo.Scripts as L
import qualified Cardano.Api.Ledger as L

-- A simple function to demonstrate the tests
increment :: Int -> Int
increment x = x + 1

main :: IO ()
main =do 
  chainInfo <- chainInfoFromEnv
  networkId <- evaluateKontract chainInfo  kGetNetworkId >>= throwFrameworkError 
  sKey <-  getEnv "SIGNKEY_FILE" >>= getSignKey
  walletAddr <- getEnvDefault "WALLET_ADDRESS" "" >>= parseAddress . T.pack
  txHolder <- newTVarIO (Nothing)
  walletUtxo :: UTxO ConwayEra <- evaluateKontract chainInfo (kQueryUtxoByAddress $ Set.singleton (addressInEraToAddressAny walletAddr)) >>= throwFrameworkError
  
  putStrLn $ "WalletAddress  : " ++ T.unpack (serialiseAddress walletAddr)
  putStrLn $ "MarketAddress  : " ++ T.unpack (serialiseAddress $ marketAddressInEra networkId)
  putStrLn $ "Wallet Balance :" ++ (toConsoleText "  "  $ utxoSum walletUtxo)

  let 
    (mintedAsset,mintBuilder) = mintNativeAsset walletVkey (AssetName $ BS8.pack "TestToken") 2
    walletVkey = getVerificationKey sKey
    walletBuilder = txWalletSignKey sKey
                  <> txWalletAddress walletAddr
    runTransactionTest' action buikderKontract = runTransactionTest'' action buikderKontract >> pure ()
    runTransactionTest'' action buikderKontract = runTransactionTest chainInfo action walletBuilder buikderKontract
    
  hspecJUnit $ sequential $ do
    describe "SimpleMarketPlaceFlow" $ do
      -- Setup shared variable with `before` hook
      before (return $ increment 1) $ do
        it "Should mint  2 Native Assets" $ \result1 -> do                            
          runTransactionTest'
                "Mint Native Asset" 
                (pure $ mintBuilder)

        it "Should place 2 tokens on sale" $ \result1 -> do
          let sellTxBuilder = sellBuilder (marketAddressInEra networkId ) (valueFromList [(mintedAsset,1)] ) 10_000_000 walletAddr 
          eTx <- runTransactionTest''
                "Place on Sell" 
                (pure $ sellTxBuilder <> sellTxBuilder)
          case eTx of 
            Right tx -> atomically$ writeTVar txHolder (Just $ getTxId $ getTxBody tx )
            _ -> pure ()

        it "Should withdraw 1 token from sale" $ \result1 -> do
          mSaleTxId <- readTVarIO txHolder
          case mSaleTxId of 
            Nothing -> expectationFailure "Sale Transaction was not successful"
            Just saleTxId -> do  
              runTransactionTest'  
                  "Withdraw" 
                  (withdrawTokenBuilder Nothing (TxIn saleTxId (TxIx 0) ))                          

        it "Should buy 1 token from sale" $ \result1 -> do
          mSaleTxId <- readTVarIO txHolder
          case mSaleTxId of 
            Nothing -> expectationFailure "Sale Transaction was not successful"
            Just saleTxId -> do                        
              runTransactionTest'  
                  "Buy" 
                  (buyTokenBuilder Nothing (TxIn saleTxId (TxIx 1) ))

runTransactionTest :: (HasKuberAPI a, HasSubmitApi a, HasChainQueryAPI a) =>
  a
  -> String
  -> TxBuilder
  -> Kontract a w FrameworkError TxBuilder
  -> IO (Either FrameworkError (Tx ConwayEra))
runTransactionTest chainInfo  action walletBuilder builderKontract = do 
    result <-evaluateKontract chainInfo  $ 
          performTransactionAndReport 
          action 
          walletBuilder  
          (builderKontract)

    result `shouldSatisfy` (\case
        Left _ -> False
        Right _ -> True
      ) 
    pure result

performTransactionAndReport :: (HasKuberAPI api,HasSubmitApi api,HasChainQueryAPI api) => String -> TxBuilder -> Kontract api w FrameworkError TxBuilder ->     Kontract api w FrameworkError (Tx ConwayEra)
performTransactionAndReport action wallet builderKontract = do
    builder <- builderKontract 
    tx <- runBuildAndSubmit  $
              builder
              <> wallet
    liftIO$ putStrLn $ action ++ " Tx submitted : " ++ (show tx)
    liftIO $ reportExUnitsandFee tx
    waitTxConfirmation tx 180
    liftIO $ do 
          putStrLn $ action ++ " Tx Confirmed: " ++ (show tx)
          pure tx

reportExUnitsandFee:: Tx ConwayEra -> IO() 
reportExUnitsandFee  = (\case  
      ShelleyTx era ledgerTx -> let 
        txWitnesses = ledgerTx ^. L.witsTxL 
        -- this should be exUnits of single script involved in the transaction
        exUnits = map snd $ map snd $  Map.toList $ L.unRedeemers $  txWitnesses ^. L.rdmrsTxWitsL
        in do 
          case exUnits of 
            [eunit]-> let eu = L.unWrapExUnits eunit
                          (mem,cpu) =   (L.exUnitsMem' eu,L.exUnitsSteps' eu)
                      in putStrLn $  "  ExUnits:  memory = " ++ show mem ++ " cpu = " ++ show cpu
            _       -> pure () 
          putStrLn $  "  Fee :   " ++ show (L.unCoin $ ledgerTx ^. L.bodyTxL ^. L.feeTxBodyL ) 
    )


waitTxConfirmation :: HasChainQueryAPI a => Tx ConwayEra -> Integer
      -> Kontract a w FrameworkError ()
waitTxConfirmation tx totalWaitSecs =  
    let txId = getTxId$ getTxBody tx
    in waitTxId txId  totalWaitSecs
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