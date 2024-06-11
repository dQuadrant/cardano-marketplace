{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Test.TestStorySimpleMarketV3 where

import Test.Hspec
import Test.Hspec.JUnit 
import Cardano.Kuber.Api 
import System.Environment.Blank (getEnvDefault)
import Cardano.Kuber.Data.Parsers
import qualified Data.Text as T
import System.Environment (getEnv)
import Cardano.Marketplace.Common.TransactionUtils
import Cardano.Marketplace.V3.Core
import Cardano.Api 
import qualified Data.ByteString.Char8 as BS8
import qualified Data.Set as Set
import GHC.Conc 
import Cardano.Kuber.Util 
import Cardano.Kuber.Console.ConsoleWritable 
import Plutus.Contracts.V3.SimpleMarketplace 
import qualified Debug.Trace as Debug
import Test.Common


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
                (pure $ createReferenceScript simpleMarketplacePlutusV3 (marketAddressInEra networkId) )
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

