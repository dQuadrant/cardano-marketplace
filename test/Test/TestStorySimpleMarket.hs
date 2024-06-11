{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Test.TestStorySimpleMarket where

import Test.Hspec ( before, describe, it, shouldBe, shouldSatisfy, expectationFailure, sequential )
import Test.Hspec.JUnit (hspecJUnit)
import Control.Monad.IO.Class (liftIO)
import Cardano.Kuber.Api 
import System.Environment.Blank (getEnvDefault)
import Cardano.Kuber.Data.Parsers
import qualified Data.Text as T
import System.Environment (getEnv)
import Cardano.Marketplace.Common.TransactionUtils
import Cardano.Marketplace.V2.Core (sellBuilder)
import Cardano.Marketplace.V2.Core
import Cardano.Api 
import qualified Data.ByteString.Char8 as BS8
import qualified Data.Set as Set
import Cardano.Api.Shelley (TxIx(..), Tx (ShelleyTx), ShelleyBasedEra (..))
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
import Plutus.Contracts.V2.SimpleMarketplace (simpleMarketplacePlutusV2)
import qualified Debug.Trace as Debug
import Cardano.Api (serialiseTxLedgerCddl)

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
  refTxHolder <- newTVarIO (Nothing)
  walletUtxo :: UTxO ConwayEra <- evaluateKontract chainInfo (kQueryUtxoByAddress $ Set.singleton (addressInEraToAddressAny walletAddr)) >>= throwFrameworkError
  
  putStrLn $ "WalletAddress  : " ++ T.unpack (serialiseAddress walletAddr)
  putStrLn $ "MarketAddress  : " ++ T.unpack (serialiseAddress $ marketAddressInEra networkId)
  putStrLn $ "Wallet Balance :" ++ (toConsoleText "  "  $ utxoSum walletUtxo)

  let 
    (mintedAsset,mintBuilder) = mintNativeAsset walletVkey (AssetName $ BS8.pack "TestToken") 4
    walletVkey = getVerificationKey sKey
    walletBuilder = txWalletSignKey sKey
                  <> txWalletAddress walletAddr 
    runTransactionTest' action builderKontract = do 
      txb <- evaluateKontract chainInfo builderKontract 
      eTx <- runTransactionTest'' action builderKontract 
      case eTx of 
        Left _ -> case txb of 
          Left _ -> pure()
          Right txb' -> Debug.traceM(action ++ " Transaction Failed: " ++ "\n" ++ (BS8.unpack $ prettyPrintJSON (txb')))  
        Right _ -> pure()
    runTransactionTest'' action buikderKontract = runTransactionTest chainInfo action walletBuilder buikderKontract
    
  hspecJUnit $ sequential $ do
    describe "SimpleMarketPlaceFlow" $ do
      -- Setup shared variable with `before` hook
      before (return $ increment 1) $ do
        it "Should mint  4 Native Assets" $ \result1 -> do                            
          runTransactionTest'
                "Mint Native Asset" 
                (pure $ mintBuilder )

        it "Should create reference script UTxO" $ \result1 -> do
          eTx <- runTransactionTest''
                "Create reference script UTxO" 
                (pure $ createReferenceScript simpleMarketplacePlutusV2 (marketAddressInEra networkId) )
          case eTx of 
            Right tx -> atomically$ writeTVar refTxHolder (Just $ getTxId $ getTxBody tx )
            _ -> pure ()

        it "Should place 4 tokens on sale" $ \result1 -> do
          let sellTxBuilder = sellBuilder (marketAddressInEra networkId ) (valueFromList [(mintedAsset,1)] ) 10_000_000 walletAddr 
          eTx <- runTransactionTest''
                "Place on Sell" 
                (pure $ sellTxBuilder <> sellTxBuilder <> sellTxBuilder <> sellTxBuilder)
          case eTx of 
            Right tx -> atomically$ writeTVar txHolder (Just $ getTxId $ getTxBody tx )
            _ -> pure ()

        it "Should withdraw 1 token from sale" $ \result1 -> do
          mSaleTxId <- readTVarIO txHolder
          case mSaleTxId of 
            Nothing -> expectationFailure "Sale Transaction was not successful"
            Just saleTxId -> do  
              let txBuilder = withdrawTokenBuilder Nothing (TxIn saleTxId (TxIx 0) )
              runTransactionTest'  
                     "Withdraw" 
                      (txBuilder)  
              
        it "Should buy 1 token from sale" $ \result1 -> do
          mSaleTxId <- readTVarIO txHolder
          case mSaleTxId of 
            Nothing -> expectationFailure "Sale Transaction was not successful"
            Just saleTxId -> do    
              let txBuilder = buyTokenBuilder Nothing (TxIn saleTxId (TxIx 1) )                      
              runTransactionTest'  
                    "Buy" 
                    (txBuilder)
        
        it "Should withdraw 1 token from sale with reference script" $ \result1 -> do
          mSaleTxId <- readTVarIO txHolder
          mRefTxId <- readTVarIO refTxHolder
          case mSaleTxId of 
            Nothing -> expectationFailure "Sale Transaction was not successful"
            Just saleTxId -> case mRefTxId of 
              Nothing -> expectationFailure "RefScript UTxO creation Transaction was not successful" 
              Just refTxId -> do  
                let txBuilder = withdrawTokenBuilder (Just $ TxIn refTxId (TxIx 0)) (TxIn saleTxId (TxIx 2) )
                runTransactionTest'  
                      "Withdraw with RefScript" 
                      (txBuilder) 
        
        it "Should buy 1 token from sale with reference script" $ \result1 -> do
          mSaleTxId <- readTVarIO txHolder
          mRefTxId <- readTVarIO refTxHolder
          case mSaleTxId of 
            Nothing -> expectationFailure "Sale Transaction was not successful"
            Just saleTxId ->case mRefTxId of 
              Nothing -> expectationFailure "RefScript UTxO creation Transaction was not successful" 
              Just refTxId -> do  
                let txBuilder = buyTokenBuilder (Just $ TxIn refTxId (TxIx 0)) (TxIn saleTxId (TxIx 3) )
                runTransactionTest'   
                  "Buy with RefScript" 
                  (txBuilder)

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

performTransactionAndReport :: (HasKuberAPI api,HasSubmitApi api,HasChainQueryAPI api) => 
  String -> 
  TxBuilder -> 
  Kontract api w FrameworkError TxBuilder -> 
  Kontract api w FrameworkError (Tx ConwayEra) 
performTransactionAndReport action wallet builderKontract = do 
  builder <- builderKontract 
  tx <- runBuildAndSubmit  $ builder <> wallet 
  let txEnvelope =  serialiseTxLedgerCddl ShelleyBasedEraConway tx 
  liftIO$ putStrLn $ action ++ " Tx submitted : " ++ (BS8.unpack $  prettyPrintJSON txEnvelope) 
  liftIO $ reportExUnitsandFee tx 
  waitTxConfirmation tx 180 
  liftIO $ do putStrLn $ action ++ " Tx Confirmed: " ++ (show $ getTxId (getTxBody tx)) 
  pure (tx)

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