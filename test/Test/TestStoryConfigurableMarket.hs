{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Test.TestStoryConfigurableMarket where

import Test.Hspec
import Test.Hspec.JUnit 
import Cardano.Kuber.Api 
import System.Environment.Blank (getEnvDefault)
import Cardano.Kuber.Data.Parsers
import qualified Data.Text as T
import System.Environment (getEnv)
import Cardano.Marketplace.Common.TransactionUtils
import Cardano.Api 
import qualified Data.ByteString.Char8 as BS8
import qualified Data.Set as Set
import GHC.Conc 
import Cardano.Kuber.Util 
import Cardano.Kuber.Console.ConsoleWritable 
import Plutus.Contracts.V2.ConfigurableMarketplace 
import qualified PlutusLedgerApi.V1.Scripts as P 
import qualified Debug.Trace as Debug
import Test.Common
import Plutus.Contracts.V2.MarketplaceConfig
import Cardano.Api.Shelley (toShelleyAddr, toShelleyScriptHash, PlutusScript (..))
import qualified PlutusTx.Builtins as BI
import Data.Maybe (fromJust)
import Cardano.Api (prettyPrintJSON)
import Cardano.Marketplace.ConfigurableMarketplace
import Cardano.Marketplace.V2.Core (makeConfigurableMarketV2Helper)
import Cardano.Marketplace.V3.Core (makeConfigurableMarketV3Helper)
import Test.TestContext
import Test.Reporting (collectReports)
import qualified Data.Map as Map



makeConfigurableMarketSpecs :: Integer -> TestContext ChainConnectInfo -> IO [SpecWith ()]
makeConfigurableMarketSpecs testIdx tContext = do 
  let makeVars = do 
        saleVar <- newTVarIO Nothing
        refVar <- newTVarIO Nothing
        configVar <- newTVarIO Nothing
        pure (configVar,saleVar,refVar)
      v2Helper = makeConfigurableMarketV2Helper (tcWalletAddr tContext) 3_000_000
      v3Helper = makeConfigurableMarketV3Helper (tcWalletAddr tContext) 3_000_000
  v2Vars <- makeVars
  v3Vars <- makeVars
  pure [
      afterAll 
          (\x -> collectReports  "Configurable Market" "V2" tContext ) 
          $ simpleMarketSpecs testIdx "ConfigurableMarketV2 Flow" v2Helper tContext (pure v2Vars)
    , afterAll 
        (\x -> collectReports  "Configurable Market" "V3" tContext) 
        $ simpleMarketSpecs  (testIdx+1) "ConfigurableMarketV3 Flow" v3Helper tContext (pure  v3Vars)
    ]

simpleMarketSpecs::  Integer ->  String -> ConfigurableMarketHelper -> TestContext ChainConnectInfo -> IO (TVar (Maybe TxId), TVar (Maybe TxId),TVar (Maybe TxId)) -> SpecWith ()
simpleMarketSpecs testIndex scriptName marketHelper context@(TestContext chainInfo networkId sKey walletAddr _ _)  ioAction =
  let 
      operatorAddr = walletAddr
      treasuryAddr= walletAddr

      marketFee = 3_000_000
      (mintedAsset,mintBuilder) = mintNativeAsset (getVerificationKey sKey) (AssetName $ BS8.pack "TestToken") 4
      runTest_ index mRef str tb = do 
        putStrLn $ (show testIndex ++ "." ++ show index ++" "++scriptName ++ " : " ++ show str)
        runTestContext_  context mRef str tb
      marketAddressInEra = plutusScriptAddr  (cmMarketScript marketHelper)  networkId
      configAddressInEra = plutusScriptAddr (cmConfigScript marketHelper) networkId
    in do 
    let 
    describe scriptName $ do
      before ioAction $ do
        it "Should mint  4 Native Assets" $ \(configTx,saleTx, refUtxo) -> do
          runTest_ 1 Nothing "Mint Native Asset"  (do 
              (UTxO utxos) ::UTxO ConwayEra <- kQueryUtxoByAddress (Set.singleton $ addressInEraToAddressAny walletAddr)
              pure $ mintBuilder   <> txConsumeUtxos (UTxO $ Map.fromList $ take 100  $ Map.toList utxos)
              
              )

        it "Should create reference script UTxO" $ \(configTx,saleTx, refUtxo) -> do
          runTest_ 2
                (Just refUtxo)
                "Create reference script UTxO" 
                (pure $ createReferenceScript (cmMarketScript marketHelper) marketAddressInEra )

        it "Should place 4 tokens on sale" $ \(configTx,saleTx, refUtxo) -> do
          let sellTxBuilder = sellBuilder marketHelper marketAddressInEra (valueFromList [(mintedAsset,1)] ) 10_000_000 walletAddr 
          runTest_ 3
            (Just saleTx)
            "Place on Sell"
            (pure $ mconcat $ take 4 $ repeat  sellTxBuilder )

        it "Should create market configuration" $ \(configTx,saleTx, refUtxo) -> do
          runTest_ 4
            (Just configTx)
                "Create market configuration"
                (pure $ txPayToScriptWithData 
                        configAddressInEra  mempty (cmConfigDatum marketHelper))

        it "Should withdraw 1 token from sale" $ \(configTx,saleTx, refUtxo) -> do
          saleTxId <- readSaleTxVar saleTx
          let txBuilder = withdrawTokenBuilder marketHelper Nothing (TxIn saleTxId (TxIx 0)) 
          runTest_ 5 Nothing "Withdraw" txBuilder

        it "Should withdraw 1 token from sale with reference script" $ \(configTx,saleTx, refUtxo) -> do 
          saleTxId <- readSaleTxVar saleTx
          refTxId <- readConfigTxVar refUtxo 
          let txBuilder = withdrawTokenBuilder marketHelper (Just $ TxIn refTxId (TxIx 0)) (TxIn saleTxId (TxIx 1) )
          runTest_ 6 Nothing "Withdraw with RefScript" txBuilder 

                

        it "Should buy 1 token from sale" $ \(configTx,saleTx, refUtxo) -> do
          saleTxId <- readSaleTxVar saleTx
          configTxId <- readConfigTxVar configTx 
          let
            feeInfo = (operatorAddr, marketFee , TxIn configTxId (TxIx 0))  
            txBuilder = buyTokenBuilder marketHelper Nothing (TxIn saleTxId (TxIx 2))  (Just feeInfo) 
          runTest_ 7 Nothing "Buy" txBuilder   
                
        it "Should buy 1 token from sale with reference script" $ \tvars -> do
          (configTxId,saleTxId,refTxId)<- readConfigSaleAndRefScriptVar  tvars
          let
            operatorAddress =operatorAddr
            feeInfo = (operatorAddress, marketFee, TxIn configTxId (TxIx 0))  
            txBuilder = buyTokenBuilder marketHelper (Just $ TxIn refTxId (TxIx 0)) (TxIn saleTxId (TxIx 3))  (Just feeInfo) 
          runTest_ 8 Nothing "Buy with RefScript" txBuilder


readConfigSaleAndRefScriptVar (z,a,b) = do 
     z' <- liftIO $ readTxId z "MarketC onfig"
     a'<-liftIO $ readTxId a "Sale"    
     b' <- liftIO $ readTxId b "Reference Script"
     pure (z',a',b')
