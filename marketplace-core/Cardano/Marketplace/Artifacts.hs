{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Cardano.Marketplace.Artifacts
  ( ScriptArtifact (..)
  , allScriptArtifacts
  , defaultOutputDir
  , artifactFileName
  , artifactPath
  , parseScriptArtifact
  , ensureArtifactsExist
  , ensureArtifactsExistAt
  , writeArtifactFile
  , loadSimpleMarketV1
  , loadSimpleMarketV1SuperLazy
  , loadSimpleMarketV2
  , loadSimpleMarketV2SuperLazy
  , loadSimpleMarketV3
  , loadSimpleMarketV3Lazy
  , loadSimpleMarketV3SuperLazy
  , loadMarketConfigV2
  , loadMarketConfigV2SuperLazy
  , loadConfigurableMarketV2
  , loadConfigurableMarketV2SuperLazy
  , loadMarketConfigV3
  , loadMarketConfigV3Lazy
  , loadMarketConfigV3SuperLazy
  , loadConfigurableMarketV3
  , loadConfigurableMarketV3Lazy
  , loadConfigurableMarketV3SuperLazy
  , artifactScriptByteSize
  ) where

import Cardano.Api
import Cardano.Kuber.Api (IsPlutusScript, toTxPlutusScript, txScriptByteSize, TxScript (TxScriptPlutus))
import qualified Data.ByteString as BS
import qualified Plutus.Contracts.V1.SimpleMarketplace as V1Simple
import qualified Plutus.Contracts.V2.ConfigurableMarketplace as V2Config
import qualified Plutus.Contracts.V2.MarketplaceConfig as V2MarketConfig
import qualified Plutus.Contracts.V2.SimpleMarketplace as V2Simple
import qualified Plutus.Contracts.V3.ConfigurableMarketplace as V3Config
import qualified Plutus.Contracts.V3.MarketplaceConfig as V3MarketConfig
import qualified Plutus.Contracts.V3.SimpleMarketplace as V3Simple
import qualified PlutusLedgerApi.V2 as PlutusV2
import qualified PlutusLedgerApi.V3 as PlutusV3
import System.Directory (createDirectoryIfMissing, doesFileExist)
import System.FilePath ((</>))

data ScriptArtifact
  = SimpleMarketV1Artifact
  | SimpleMarketV1SuperLazyArtifact
  | SimpleMarketV2Artifact
  | SimpleMarketV2SuperLazyArtifact
  | SimpleMarketV3Artifact
  | SimpleMarketV3LazyArtifact
  | SimpleMarketV3SuperLazyArtifact
  | MarketConfigV2Artifact
  | MarketConfigV2SuperLazyArtifact
  | ConfigurableMarketV2Artifact
  | ConfigurableMarketV2SuperLazyArtifact
  | MarketConfigV3Artifact
  | MarketConfigV3LazyArtifact
  | MarketConfigV3SuperLazyArtifact
  | ConfigurableMarketV3Artifact
  | ConfigurableMarketV3LazyArtifact
  | ConfigurableMarketV3SuperLazyArtifact
  deriving (Eq, Ord, Show, Enum, Bounded)

allScriptArtifacts :: [ScriptArtifact]
allScriptArtifacts = [minBound .. maxBound]

defaultOutputDir :: FilePath
defaultOutputDir = "outputs"

artifactFileName :: ScriptArtifact -> FilePath
artifactFileName artifact = case artifact of
  SimpleMarketV1Artifact -> "simple-market-v1.plutus"
  SimpleMarketV1SuperLazyArtifact -> "simple-market-v1-superlazy.plutus"
  SimpleMarketV2Artifact -> "simple-market-v2.plutus"
  SimpleMarketV2SuperLazyArtifact -> "simple-market-v2-superlazy.plutus"
  SimpleMarketV3Artifact -> "simple-market-v3.plutus"
  SimpleMarketV3LazyArtifact -> "simple-market-v3-lazy.plutus"
  SimpleMarketV3SuperLazyArtifact -> "simple-market-v3-superlazy.plutus"
  MarketConfigV2Artifact -> "market-config-v2.plutus"
  MarketConfigV2SuperLazyArtifact -> "market-config-v2-superlazy.plutus"
  ConfigurableMarketV2Artifact -> "configurable-market-v2.plutus"
  ConfigurableMarketV2SuperLazyArtifact -> "configurable-market-v2-superlazy.plutus"
  MarketConfigV3Artifact -> "market-config-v3.plutus"
  MarketConfigV3LazyArtifact -> "market-config-v3-lazy.plutus"
  MarketConfigV3SuperLazyArtifact -> "market-config-v3-superlazy.plutus"
  ConfigurableMarketV3Artifact -> "configurable-market-v3.plutus"
  ConfigurableMarketV3LazyArtifact -> "configurable-market-v3-lazy.plutus"
  ConfigurableMarketV3SuperLazyArtifact -> "configurable-market-v3-superlazy.plutus"

artifactPath :: FilePath -> ScriptArtifact -> FilePath
artifactPath outputDir artifact = outputDir </> artifactFileName artifact

ensureArtifactsExist :: IO ()
ensureArtifactsExist = ensureArtifactsExistAt defaultOutputDir

ensureArtifactsExistAt :: FilePath -> IO ()
ensureArtifactsExistAt outputDir =
  mapM_ ensureOne allScriptArtifacts
  where
    ensureOne artifact = do
      let path = artifactPath outputDir artifact
      exists <- doesFileExist path
      if exists
        then pure ()
        else fail $
          "Missing script artifact: "
            ++ path
            ++ "\nRun `cabal run market-cli -- gen-scripts` first."

writeScriptArtifact :: HasTextEnvelope a => FilePath -> ScriptArtifact -> TextEnvelopeDescr -> a -> IO ()
writeScriptArtifact outputDir artifact description value = do
  let path = artifactPath outputDir artifact
      envelope = serialiseToTextEnvelope (Just description) value
  BS.writeFile path (prettyPrintJSON envelope)

parseScriptArtifact :: FilePath -> Maybe ScriptArtifact
parseScriptArtifact fileName =
  lookup fileName [(artifactFileName artifact, artifact) | artifact <- allScriptArtifacts]

writeArtifactFile :: FilePath -> ScriptArtifact -> IO ()
writeArtifactFile outputDir artifact = do
  createDirectoryIfMissing True outputDir
  case artifact of
    SimpleMarketV1Artifact ->
      writeScriptArtifact outputDir artifact "SimpleMarketplaceV1" V1Simple.simpleMarketplacePlutusV1
    SimpleMarketV1SuperLazyArtifact ->
      writeScriptArtifact outputDir artifact "SimpleMarketplaceV1SuperLazy" V1Simple.simpleMarketplacePlutusV1SuperLazy
    SimpleMarketV2Artifact ->
      writeScriptArtifact outputDir artifact "SimpleMarketplaceV2" V2Simple.simpleMarketplacePlutusV2
    SimpleMarketV2SuperLazyArtifact ->
      writeScriptArtifact outputDir artifact "SimpleMarketplaceV2SuperLazy" V2Simple.simpleMarketplacePlutusV2SuperLazy
    SimpleMarketV3Artifact ->
      writeScriptArtifact outputDir artifact "SimpleMarketplaceV3" V3Simple.simpleMarketplacePlutusV3
    SimpleMarketV3LazyArtifact ->
      writeScriptArtifact outputDir artifact "SimpleMarketplaceV3Lazy" V3Simple.simpleMarketplacePlutusV3Lazy
    SimpleMarketV3SuperLazyArtifact ->
      writeScriptArtifact outputDir artifact "SimpleMarketplaceV3SuperLazy" V3Simple.simpleMarketplacePlutusV3SuperLazy
    MarketConfigV2Artifact ->
      writeScriptArtifact outputDir artifact "MarketConfigV2" V2MarketConfig.marketConfigPlutusScript
    MarketConfigV2SuperLazyArtifact ->
      writeScriptArtifact outputDir artifact "MarketConfigV2SuperLazy" V2MarketConfig.marketConfigPlutusScriptSuperLazy
    ConfigurableMarketV2Artifact -> do
      configV2 <- loadScriptArtifactAt outputDir MarketConfigV2Artifact
      writeScriptArtifact outputDir artifact "ConfigurableMarketV2" (mkConfigurableMarketV2 configV2)
    ConfigurableMarketV2SuperLazyArtifact -> do
      configV2 <- loadScriptArtifactAt outputDir MarketConfigV2SuperLazyArtifact
      writeScriptArtifact outputDir artifact "ConfigurableMarketV2SuperLazy" (mkConfigurableMarketV2SuperLazy configV2)
    MarketConfigV3Artifact ->
      writeScriptArtifact outputDir artifact "MarketConfigV3" V3MarketConfig.marketConfigPlutusScript
    MarketConfigV3LazyArtifact ->
      writeScriptArtifact outputDir artifact "MarketConfigV3Lazy" V3MarketConfig.marketConfigPlutusScriptLazy
    MarketConfigV3SuperLazyArtifact ->
      writeScriptArtifact outputDir artifact "MarketConfigV3SuperLazy" V3MarketConfig.marketConfigPlutusScriptSuperLazy
    ConfigurableMarketV3Artifact -> do
      configV3 <- loadScriptArtifactAt outputDir MarketConfigV3Artifact
      writeScriptArtifact outputDir artifact "ConfigurableMarketV3" (mkConfigurableMarketV3 configV3)
    ConfigurableMarketV3LazyArtifact -> do
      configV3 <- loadScriptArtifactAt outputDir MarketConfigV3LazyArtifact
      writeScriptArtifact outputDir artifact "ConfigurableMarketV3Lazy" (mkConfigurableMarketV3Lazy configV3)
    ConfigurableMarketV3SuperLazyArtifact -> do
      configV3 <- loadScriptArtifactAt outputDir MarketConfigV3SuperLazyArtifact
      writeScriptArtifact outputDir artifact "ConfigurableMarketV3SuperLazy" (mkConfigurableMarketV3SuperLazy configV3)

loadSimpleMarketV1 :: IO (PlutusScript PlutusScriptV1)
loadSimpleMarketV1 = loadScriptArtifact SimpleMarketV1Artifact

loadSimpleMarketV1SuperLazy :: IO (PlutusScript PlutusScriptV1)
loadSimpleMarketV1SuperLazy = loadScriptArtifact SimpleMarketV1SuperLazyArtifact

loadSimpleMarketV2 :: IO (PlutusScript PlutusScriptV2)
loadSimpleMarketV2 = loadScriptArtifact SimpleMarketV2Artifact

loadSimpleMarketV2SuperLazy :: IO (PlutusScript PlutusScriptV2)
loadSimpleMarketV2SuperLazy = loadScriptArtifact SimpleMarketV2SuperLazyArtifact

loadSimpleMarketV3 :: IO (PlutusScript PlutusScriptV3)
loadSimpleMarketV3 = loadScriptArtifact SimpleMarketV3Artifact

loadSimpleMarketV3Lazy :: IO (PlutusScript PlutusScriptV3)
loadSimpleMarketV3Lazy = loadScriptArtifact SimpleMarketV3LazyArtifact

loadSimpleMarketV3SuperLazy :: IO (PlutusScript PlutusScriptV3)
loadSimpleMarketV3SuperLazy = loadScriptArtifact SimpleMarketV3SuperLazyArtifact

loadMarketConfigV2 :: IO (PlutusScript PlutusScriptV2)
loadMarketConfigV2 = loadScriptArtifact MarketConfigV2Artifact

loadMarketConfigV2SuperLazy :: IO (PlutusScript PlutusScriptV2)
loadMarketConfigV2SuperLazy = loadScriptArtifact MarketConfigV2SuperLazyArtifact

loadConfigurableMarketV2 :: IO (PlutusScript PlutusScriptV2)
loadConfigurableMarketV2 = loadScriptArtifact ConfigurableMarketV2Artifact

loadConfigurableMarketV2SuperLazy :: IO (PlutusScript PlutusScriptV2)
loadConfigurableMarketV2SuperLazy = loadScriptArtifact ConfigurableMarketV2SuperLazyArtifact

loadMarketConfigV3 :: IO (PlutusScript PlutusScriptV3)
loadMarketConfigV3 = loadScriptArtifact MarketConfigV3Artifact

loadMarketConfigV3Lazy :: IO (PlutusScript PlutusScriptV3)
loadMarketConfigV3Lazy = loadScriptArtifact MarketConfigV3LazyArtifact

loadMarketConfigV3SuperLazy :: IO (PlutusScript PlutusScriptV3)
loadMarketConfigV3SuperLazy = loadScriptArtifact MarketConfigV3SuperLazyArtifact

loadConfigurableMarketV3 :: IO (PlutusScript PlutusScriptV3)
loadConfigurableMarketV3 = loadScriptArtifact ConfigurableMarketV3Artifact

loadConfigurableMarketV3Lazy :: IO (PlutusScript PlutusScriptV3)
loadConfigurableMarketV3Lazy = loadScriptArtifact ConfigurableMarketV3LazyArtifact

loadConfigurableMarketV3SuperLazy :: IO (PlutusScript PlutusScriptV3)
loadConfigurableMarketV3SuperLazy = loadScriptArtifact ConfigurableMarketV3SuperLazyArtifact

artifactScriptByteSize :: ScriptArtifact -> IO Int
artifactScriptByteSize artifact = case artifact of
  SimpleMarketV1Artifact -> txScriptSize <$> loadSimpleMarketV1
  SimpleMarketV1SuperLazyArtifact -> txScriptSize <$> loadSimpleMarketV1SuperLazy
  SimpleMarketV2Artifact -> txScriptSize <$> loadSimpleMarketV2
  SimpleMarketV2SuperLazyArtifact -> txScriptSize <$> loadSimpleMarketV2SuperLazy
  SimpleMarketV3Artifact -> txScriptSize <$> loadSimpleMarketV3
  SimpleMarketV3LazyArtifact -> txScriptSize <$> loadSimpleMarketV3Lazy
  SimpleMarketV3SuperLazyArtifact -> txScriptSize <$> loadSimpleMarketV3SuperLazy
  MarketConfigV2Artifact -> txScriptSize <$> loadMarketConfigV2
  MarketConfigV2SuperLazyArtifact -> txScriptSize <$> loadMarketConfigV2SuperLazy
  ConfigurableMarketV2Artifact -> txScriptSize <$> loadConfigurableMarketV2
  ConfigurableMarketV2SuperLazyArtifact -> txScriptSize <$> loadConfigurableMarketV2SuperLazy
  MarketConfigV3Artifact -> txScriptSize <$> loadMarketConfigV3
  MarketConfigV3LazyArtifact -> txScriptSize <$> loadMarketConfigV3Lazy
  MarketConfigV3SuperLazyArtifact -> txScriptSize <$> loadMarketConfigV3SuperLazy
  ConfigurableMarketV3Artifact -> txScriptSize <$> loadConfigurableMarketV3
  ConfigurableMarketV3LazyArtifact -> txScriptSize <$> loadConfigurableMarketV3Lazy
  ConfigurableMarketV3SuperLazyArtifact -> txScriptSize <$> loadConfigurableMarketV3SuperLazy

loadScriptArtifact :: forall a. HasTextEnvelope a => ScriptArtifact -> IO a
loadScriptArtifact artifact = loadScriptArtifactAt @a defaultOutputDir artifact

loadScriptArtifactAt :: forall a. HasTextEnvelope a => FilePath -> ScriptArtifact -> IO a
loadScriptArtifactAt outputDir artifact = do
  let path = artifactPath outputDir artifact
  result <- readFileTextEnvelope @a (File path)
  case result of
    Right value -> pure value
    Left err ->
      fail $
        "Unable to load script artifact "
          ++ path
          ++ ": "
          ++ show err
          ++ "\nRun `cabal run market-cli -- gen-scripts` first."

txScriptSize :: IsPlutusScript script => script -> Int
txScriptSize script = txScriptByteSize $ TxScriptPlutus $ toTxPlutusScript script

mkConfigurableMarketV2 :: PlutusScript PlutusScriptV2 -> PlutusScript PlutusScriptV2
mkConfigurableMarketV2 configScript =
  V2Config.configurableMarketPlutusScript $
    V2Config.MarketConstructor $
      PlutusV2.toBuiltin $
        serialiseToRawBytes $
          hashScript $
            PlutusScript PlutusScriptV2 configScript

mkConfigurableMarketV2SuperLazy :: PlutusScript PlutusScriptV2 -> PlutusScript PlutusScriptV2
mkConfigurableMarketV2SuperLazy configScript =
  V2Config.configurableMarketPlutusScriptSuperLazy $
    V2Config.MarketConstructor $
      PlutusV2.toBuiltin $
        serialiseToRawBytes $
          hashScript $
            PlutusScript PlutusScriptV2 configScript

mkConfigurableMarketV3 :: PlutusScript PlutusScriptV3 -> PlutusScript PlutusScriptV3
mkConfigurableMarketV3 configScript =
  V3Config.configurableMarketPlutusScript $
    V3Config.MarketConstructor $
      PlutusV3.ScriptHash $
        PlutusV3.toBuiltin $
          serialiseToRawBytes $
            hashScript $
              PlutusScript PlutusScriptV3 configScript

mkConfigurableMarketV3Lazy :: PlutusScript PlutusScriptV3 -> PlutusScript PlutusScriptV3
mkConfigurableMarketV3Lazy configScript =
  V3Config.configurableMarketPlutusScriptLazy $
    V3Config.MarketConstructor $
      PlutusV3.ScriptHash $
        PlutusV3.toBuiltin $
          serialiseToRawBytes $
            hashScript $
              PlutusScript PlutusScriptV3 configScript

mkConfigurableMarketV3SuperLazy :: PlutusScript PlutusScriptV3 -> PlutusScript PlutusScriptV3
mkConfigurableMarketV3SuperLazy configScript =
  V3Config.configurableMarketPlutusScriptSuperLazy $
    V3Config.MarketConstructor $
      PlutusV3.ScriptHash $
        PlutusV3.toBuiltin $
          serialiseToRawBytes $
            hashScript $
              PlutusScript PlutusScriptV3 configScript
