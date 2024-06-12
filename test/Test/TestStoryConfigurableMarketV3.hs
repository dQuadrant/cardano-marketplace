{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Test.TestStoryConfigurableMarketV3 where

import Test.Hspec
import Test.Hspec.JUnit 
import Cardano.Kuber.Api 
import System.Environment.Blank (getEnvDefault)
import Cardano.Kuber.Data.Parsers
import qualified Data.Text as T
import System.Environment (getEnv)
import Cardano.Marketplace.Common.TransactionUtils
import Cardano.Marketplace.V3.Core (sellBuilder, buyTokenBuilder)
import Cardano.Api 
import qualified Data.ByteString.Char8 as BS8
import qualified Data.Set as Set
import GHC.Conc 
import Cardano.Kuber.Util 
import Cardano.Kuber.Console.ConsoleWritable 
import Plutus.Contracts.V3.ConfigurableMarketplace 
import qualified PlutusLedgerApi.V1.Scripts as P 
import qualified Debug.Trace as Debug
import Test.Common
import Plutus.Contracts.V3.MarketplaceConfig
import Cardano.Api.Shelley (toShelleyAddr, toShelleyScriptHash, PlutusScript (..))
import qualified PlutusTx.Builtins as BI
import Cardano.Marketplace.V3.Core (withdrawTokenBuilder)
import Data.Maybe (fromJust)
import Cardano.Api (prettyPrintJSON)

main:: IO ()
main = do 
  chainInfo <- chainInfoFromEnv
  networkId <- evaluateKontract chainInfo  kGetNetworkId >>= throwFrameworkError 
  sKey <-  getEnv "SIGNKEY_FILE" >>= getSignKey
  -- buyerSKey <- getEnv "BUYER_SIGNKEY_FILE" >>= getSignKey
  walletAddr <- getEnvDefault "WALLET_ADDRESS" "" >>= parseAddress . T.pack
  -- buyerWalletAddr <- getEnvDefault "BUYER_WALLET_ADDRESS" "" >>= parseAddress . T.pack 
  txHolder <- newTVarIO (Nothing)
  refTxHolder <- newTVarIO (Nothing)
  configTxHolder <- newTVarIO (Nothing)
  walletUtxo :: UTxO ConwayEra <- evaluateKontract chainInfo (kQueryUtxoByAddress $ Set.singleton (addressInEraToAddressAny walletAddr)) >>= throwFrameworkError
  let
    onlyAdaValue = valueFromList [(AdaAssetId,5_000_000)]
    toPlutusScriptHash h = P.ScriptHash $ BI.toBuiltin $ serialiseToRawBytes h
    toPlutusAddr addr= anyAddressInShelleyBasedEra ShelleyBasedEraConway (addressInEraToAddressAny addr) 
    operatorAddress = addrInEraToPlutusAddress walletAddr 
    ownerAddress = addrInEraToPlutusAddress walletAddr
    marketConfig = MarketConfig operatorAddress operatorAddress 3_000_000
    marketConstructor = MarketConstructor  ( toPlutusScriptHash $ hashScript  marketConfigPlutusScript)
    configAddress = marketConfigAddress networkId
    marketScript = configurableMarketPlutusScript marketConstructor
    marketAddrInEra = configurableMarketAddress marketConstructor networkId
  putStrLn $ "WalletAddress  : " ++ T.unpack (serialiseAddress walletAddr)
  putStrLn $ "MarketAddress  : " ++ T.unpack (serialiseAddress $ marketAddrInEra)
  putStrLn $ "MarketConfigAddress  : " ++ T.unpack (serialiseAddress $ configAddress)
  putStrLn $ "Wallet Balance :" ++ (toConsoleText "  "  $ utxoSum walletUtxo)  
  let
    assetCost = 10_000_000
    walletVkey = getVerificationKey sKey
    (mintedAssset, mintBuilder) = mintNativeAsset walletVkey (AssetName $ BS8.pack "ConfigurableToken") 4
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
    describe "ConfigurableMarketPlaceFlow" $ do 
      before (return $ increment 1) $ do 
        it "Should mint 4 Native Assets" $ \result1 -> do 
          runTransactionTest' "Mint Native Asset" (pure $ mintBuilder)

        it "Should create reference script UTxO" $ \result1 -> do 
          eTx <- runTransactionTest'' 
                  "Create reference script UTxO" 
                  (pure $ createReferenceScript marketScript marketAddrInEra)
          case eTx of 
            Right tx -> atomically $ writeTVar refTxHolder (Just $ getTxId $ getTxBody tx)
            _ -> pure()

        it "Should Place 4 tokens on sale" $ \result1 -> do 
          let sellTxBuilder = sellBuilder marketAddrInEra (valueFromList [(mintedAssset, 1)]) assetCost walletAddr 
          eTx <- runTransactionTest''
                "Place on sell"
                (pure $ sellTxBuilder <> sellTxBuilder <> sellTxBuilder <> sellTxBuilder)
          case eTx of 
            Right tx -> atomically $ writeTVar txHolder (Just $ getTxId $ getTxBody tx)
            _ -> pure ()

        it "Should create market configuration" $ \result1 -> do 
          let configTxBuilder = txPayToScriptWithData configAddress onlyAdaValue (unsafeHashableScriptData $ dataToScriptData marketConfig)
          eTx <- runTransactionTest''
                "Create market configuration"
                (pure configTxBuilder)
          case eTx of 
            Right tx -> atomically $ writeTVar configTxHolder (Just $ getTxId $ getTxBody tx)
            _ -> pure () 

        it "Should withdraw 1 token from sale" $ \result1 -> do
          mSaleTxId <- readTVarIO txHolder
          case mSaleTxId of 
            Nothing -> expectationFailure "Sale Transaction was not successful"
            Just saleTxId -> do 
              let txBuilder = withdrawTokenBuilder Nothing (TxIn saleTxId (TxIx 0)) marketScript 
              runTransactionTest' "Withdraw" txBuilder

        it "Should withdraw 1 token from sale with reference script" $ \result1 -> do 
          mSaleTxId <- readTVarIO txHolder
          mRefTxId <- readTVarIO refTxHolder 
          case mSaleTxId of 
            Nothing -> expectationFailure "Sale Transaction was not successful"
            Just saleTxId -> case mRefTxId of 
              Nothing -> expectationFailure "RefScript UTxO creation Transaction was not successful" 
              Just refTxId -> do  
                let txBuilder = withdrawTokenBuilder (Just $ TxIn refTxId (TxIx 0)) (TxIn saleTxId (TxIx 2) ) marketScript
                runTransactionTest' "Withdraw with RefScript" txBuilder 

        it "Should buy 1 token from sale" $ \result1 -> do
          mSaleTxId <- readTVarIO txHolder
          mConfigTxId <- readTVarIO configTxHolder 
          let
            operatorAddress = AddressInEra (ShelleyAddressInEra shelleyBasedEra) 
              (fromJust $ fromPlutusAddress networkId (marketFeeReceiverAddress marketConfig))  
          case mSaleTxId of 
            Nothing -> expectationFailure "Sale Transaction was not successful"
            Just saleTxId -> case mConfigTxId of 
              Nothing -> expectationFailure "Marketplace Config Transaction was not successful" 
              Just configTxId -> do    
                let
                  feeInfo = (operatorAddress, marketFee marketConfig, TxIn configTxId (TxIx 0))  
                  txBuilder = buyTokenBuilder Nothing (TxIn saleTxId (TxIx 1)) marketScript (Just feeInfo) 
                runTransactionTest' "Buy" txBuilder   
        
        it "Should buy 1 token from sale with reference script" $ \result1 -> do
          mSaleTxId <- readTVarIO txHolder
          mConfigTxId <- readTVarIO configTxHolder 
          mRefTxId <- readTVarIO refTxHolder
          let
            operatorAddress = AddressInEra (ShelleyAddressInEra shelleyBasedEra) 
              (fromJust $ fromPlutusAddress networkId (marketFeeReceiverAddress marketConfig))  
          case mSaleTxId of 
            Nothing -> expectationFailure "Sale Transaction was not successful"
            Just saleTxId -> case mConfigTxId of 
              Nothing -> expectationFailure "Marketplace Config Transaction was not successful" 
              Just configTxId -> case mRefTxId of 
                Nothing -> expectationFailure "RefScript UTxO creation Transaction was not successful"
                Just refTxId -> do    
                  let
                    feeInfo = (operatorAddress, marketFee marketConfig, TxIn configTxId (TxIx 0))  
                    txBuilder = buyTokenBuilder (Just $ TxIn refTxId (TxIx 0)) (TxIn saleTxId (TxIx 1)) marketScript (Just feeInfo) 
                  runTransactionTest' "Buy" txBuilder