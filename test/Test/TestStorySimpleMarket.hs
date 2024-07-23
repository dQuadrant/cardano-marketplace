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
import Cardano.Marketplace.V2.Core (simpleMarketV2Helper, simpleMarketV2HelperSuperLazy)
import Cardano.Marketplace.V3.Core (simpleMarketV3Helper, simpleMarketV3HelperLazy, simpleMarketV3HelperSuperLazy)
import Test.TestContext
import Test.Reporting (collectReports, addTagMetric)
import qualified Data.Map as Map


makeSimpleMarketSpecs :: Integer -> TestContext ChainConnectInfo -> IO [SpecWith ()]
makeSimpleMarketSpecs start_index tContext = do 
  let makeVars = do 
        saleVar <- newTVarIO Nothing
        refVar <- newTVarIO Nothing
        pure (saleVar,refVar)
  v2Vars <- makeVars
  v2VarsSuperLazy <- makeVars
  v3Vars <- makeVars
  v3VarsLazy <- makeVars
  v3VarsSuperLazy <- makeVars

  addTagMetric tContext (TagMetric "Simple Market" "V2" "ScriptBytes" (show $ txScriptByteSize $ TxScriptPlutus $ simpleMarketScript simpleMarketV2Helper ))
  addTagMetric tContext (TagMetric "Simple Market" "V2 Super Lazy" "ScriptBytes" (show $ txScriptByteSize $ TxScriptPlutus $ simpleMarketScript simpleMarketV2HelperSuperLazy ))
  addTagMetric tContext (TagMetric "Simple Market" "V3" "ScriptBytes" (show $ txScriptByteSize $ TxScriptPlutus $ simpleMarketScript simpleMarketV3Helper ))
  addTagMetric tContext (TagMetric "Simple Market" "V3 Lazy" "ScriptBytes" (show $ txScriptByteSize $ TxScriptPlutus $ simpleMarketScript simpleMarketV3HelperLazy ))
  addTagMetric tContext (TagMetric "Simple Market" "V3 Super Lazy" "ScriptBytes" (show $ txScriptByteSize $ TxScriptPlutus $ simpleMarketScript simpleMarketV3HelperSuperLazy ))

  pure [
      afterAll
        (\x -> collectReports  "Simple Market" "V2" tContext ) 
        $ simpleMarketSpecs "SimpleMarketV2 Flow" start_index simpleMarketV2Helper tContext (pure v2Vars)
    , afterAll
        (\x -> collectReports  "Simple Market" "V2 Super Lazy" tContext ) 
        $ simpleMarketSpecs "SimpleMarketV2SuperLazy Flow" (start_index + 1) simpleMarketV2HelperSuperLazy tContext (pure v2VarsSuperLazy)
    , afterAll
        (\x -> collectReports  "Simple Market" "V3" tContext ) 
        $ simpleMarketSpecs "SimpleMarketV3 Flow" (start_index+2) simpleMarketV3Helper tContext (pure  v3Vars)
    , afterAll
        (\x -> collectReports  "Simple Market" "V3 Lazy" tContext ) 
        $ simpleMarketSpecs "SimpleMarketV3Lazy Flow" (start_index+3) simpleMarketV3HelperLazy tContext (pure  v3VarsLazy)
    , afterAll
        (\x -> collectReports  "Simple Market" "V3 Super Lazy" tContext ) 
        $ simpleMarketSpecs "SimpleMarketV3SuperLazy Flow" (start_index+4) simpleMarketV3HelperSuperLazy tContext (pure  v3VarsSuperLazy)
    ]

simpleMarketSpecs::  String-> Integer -> SimpleMarketHelper -> TestContext ChainConnectInfo -> IO (TVar (Maybe TxId), TVar (Maybe TxId)) -> SpecWith ()
simpleMarketSpecs scriptName testIndex marketHelper context@(TestContext chainInfo networkId sKey walletAddr _ _ _ )  ioAction =
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
              (UTxO utxos) ::UTxO ConwayEra <- kQueryUtxoByAddress (Set.singleton $ addressInEraToAddressAny walletAddr)
              pure $ mintBuilder   <> txConsumeUtxos (UTxO $ Map.fromList $ take 100  $ Map.toList utxos)
                      <> txPayTo walletAddr (valueFromList [(AdaAssetId,5_000_000)])
                      <> txPayTo walletAddr (valueFromList [(AdaAssetId,10_000_000)])
                      <> txPayTo walletAddr (valueFromList [(AdaAssetId,20_000_000)])
                      <> txPayTo walletAddr (valueFromList [(AdaAssetId,30_000_000)])
                      -- create extra utxos that might be required

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

