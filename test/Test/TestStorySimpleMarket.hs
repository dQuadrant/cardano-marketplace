{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Test.TestStorySimpleMarket(makeSimpleMarketSpecs) where

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
import GHC.Conc ( atomically, newTVarIO, readTVarIO, writeTVar, newTVar, TVar ) 
import Cardano.Kuber.Util 
import Cardano.Kuber.Console.ConsoleWritable 
import qualified Debug.Trace as Debug
import Test.Common
import Cardano.Marketplace.SimpleMarketplace
import Cardano.Marketplace.V2.Core (simpleMarketV2Helper)
import Cardano.Marketplace.V3.Core (simpleMarketV3Helper)
import Test.TestContext
import Test.Reporting (collectReports)


makeSimpleMarketSpecs :: Integer -> TestContext ChainConnectInfo -> IO [SpecWith ()]
makeSimpleMarketSpecs start_index tContext = do 
  let makeVars = do 
        saleVar <- newTVarIO Nothing
        refVar <- newTVarIO Nothing
        pure (saleVar,refVar)
  v2Vars <- makeVars
  v3Vars <- makeVars
  
  pure [
      afterAll
        (\x -> collectReports  "Simple Market" "V2" tContext ) 
        $ simpleMarketSpecs "SimpleMarketV2 Flow" start_index simpleMarketV2Helper tContext (pure v2Vars)
    , afterAll
        (\x -> collectReports  "Simple Market" "V3" tContext ) 
        $ simpleMarketSpecs "SimpleMarketV3 Flow" (start_index+1) simpleMarketV3Helper tContext (pure  v3Vars)
    ]

simpleMarketSpecs::  String-> Integer -> SimpleMarketHelper -> TestContext ChainConnectInfo -> IO (TVar (Maybe TxId), TVar (Maybe TxId)) -> SpecWith ()
simpleMarketSpecs scriptName testIndex marketHelper context@(TestContext chainInfo networkId sKey walletAddr _ _ )  ioAction =
  let 
      (mintedAsset,mintBuilder) = mintNativeAsset (getVerificationKey sKey) (AssetName $ BS8.pack "TestToken") 4
      runTest_ index mRef str tb = do 
        putStrLn $ (show testIndex ++ "." ++ show index ++" "++scriptName ++ " : " ++ show str)
        runTestContext_  context mRef str tb
      marketAddressInEra = plutusScriptAddr  (simpleMarketScript marketHelper)  networkId
    in do 
    let 
    describe scriptName $ do
      -- Setup shared variable with `before` hook
      before ioAction $ do
        it  "Should mint  4 Native Assets" $ \(saleTx, refUtxo) -> do
          runTest_  1 Nothing "Mint Native Asset"  (do 
              utxos ::UTxO ConwayEra <- kQueryUtxoByAddress (Set.singleton $ addressInEraToAddressAny walletAddr)
              pure $ mintBuilder   <> txConsumeUtxos utxos
              )


        it "Should create reference script UTxO" $ \(saleTx, refUtxo) -> do
          runTest_ 2
                (Just refUtxo)
                "Create reference script UTxO" 
                (pure $ createReferenceScript (simpleMarketScript marketHelper) marketAddressInEra )

        it "Should place 4 tokens on sale" $ \(saleTx, refUtxo) -> do
          let sellTxBuilder = sellBuilder marketHelper marketAddressInEra (valueFromList [(mintedAsset,1)] ) 10_000_000 walletAddr 
          runTest_ 3
            (Just saleTx)
            "Place on Sell"
            (pure $ mconcat $ take 4 $ repeat  sellTxBuilder )

        it "Should withdraw 1 token from sale" $ \(saleTx, refUtxo) -> do
          saleTxId <- readSaleTxVar saleTx 
          runTest_  4 Nothing "Withdraw"
            $  withdrawTokenBuilder marketHelper Nothing (TxIn saleTxId (TxIx 0) )
              
        it "Should buy 1 token from sale" $ \(saleTx, refUtxo) -> do
          saleTxId <- readSaleTxVar saleTx 
          runTest_  5 Nothing "Buy" 
            $ buyTokenBuilder marketHelper Nothing (TxIn saleTxId (TxIx 1) ) Nothing
        
        it "Should withdraw 1 token from sale with reference script" $ \vars -> do
          (saleTxId,refUtxoId ) <- readSaleAndRefScriptVar vars
          runTest_  6 Nothing "Withdraw with RefScript" 
            $ withdrawTokenBuilder marketHelper (Just $ TxIn refUtxoId (TxIx 0)) (TxIn saleTxId (TxIx 2) )       
        
        it "Should buy 1 token from sale with reference script" $ \vars -> do
          (saleTxId,refUtxoId ) <- readSaleAndRefScriptVar vars
          runTest_  7 Nothing "Buy with RefScript"
            $ buyTokenBuilder marketHelper (Just $ TxIn refUtxoId (TxIx 0)) (TxIn saleTxId (TxIx 3) ) Nothing

