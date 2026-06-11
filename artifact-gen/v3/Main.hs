{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Main where

import Cardano.Api
import qualified Data.ByteString as BS
import qualified Plutus.Contracts.V3.ConfigurableMarketplace as V3Config
import qualified Plutus.Contracts.V3.MarketplaceConfig as V3MarketConfig
import qualified Plutus.Contracts.V3.SimpleMarketplace as V3Simple
import qualified PlutusLedgerApi.V3 as PlutusV3
import System.Directory (createDirectoryIfMissing)
import System.Environment (getArgs)
import System.FilePath ((</>))

main :: IO ()
main = do
  args <- getArgs
  let outputDir = case args of
        [] -> "outputs"
        dir : _ -> dir
  createDirectoryIfMissing True outputDir

  writeArtifact outputDir "simple-market-v3.plutus" "SimpleMarketplaceV3" V3Simple.simpleMarketplacePlutusV3
  writeArtifact outputDir "simple-market-v3-lazy.plutus" "SimpleMarketplaceV3Lazy" V3Simple.simpleMarketplacePlutusV3Lazy
  writeArtifact outputDir "simple-market-v3-superlazy.plutus" "SimpleMarketplaceV3SuperLazy" V3Simple.simpleMarketplacePlutusV3SuperLazy
  writeArtifact outputDir "market-config-v3.plutus" "MarketConfigV3" V3MarketConfig.marketConfigPlutusScript
  writeArtifact outputDir "market-config-v3-lazy.plutus" "MarketConfigV3Lazy" V3MarketConfig.marketConfigPlutusScriptLazy
  writeArtifact outputDir "market-config-v3-superlazy.plutus" "MarketConfigV3SuperLazy" V3MarketConfig.marketConfigPlutusScriptSuperLazy

  configV3 <- readScript @(PlutusScript PlutusScriptV3) (outputDir </> "market-config-v3.plutus")
  configV3Lazy <- readScript @(PlutusScript PlutusScriptV3) (outputDir </> "market-config-v3-lazy.plutus")
  configV3SuperLazy <- readScript @(PlutusScript PlutusScriptV3) (outputDir </> "market-config-v3-superlazy.plutus")

  writeArtifact outputDir "configurable-market-v3.plutus" "ConfigurableMarketV3" (mkConfigurableMarketV3 configV3)
  writeArtifact outputDir "configurable-market-v3-lazy.plutus" "ConfigurableMarketV3Lazy" (mkConfigurableMarketV3Lazy configV3Lazy)
  writeArtifact outputDir "configurable-market-v3-superlazy.plutus" "ConfigurableMarketV3SuperLazy" (mkConfigurableMarketV3SuperLazy configV3SuperLazy)

writeArtifact :: HasTextEnvelope a => FilePath -> FilePath -> TextEnvelopeDescr -> a -> IO ()
writeArtifact outputDir fileName description value =
  BS.writeFile (outputDir </> fileName) $ prettyPrintJSON $ serialiseToTextEnvelope (Just description) value

readScript :: forall a. HasTextEnvelope a => FilePath -> IO a
readScript path = do
  result <- readFileTextEnvelope @a (File path)
  case result of
    Right value -> pure value
    Left err -> fail $ "Unable to load script artifact " ++ path ++ ": " ++ show err

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
