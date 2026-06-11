{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Main where

import Cardano.Api
import qualified Data.ByteString as BS
import qualified Plutus.Contracts.V2.ConfigurableMarketplace as V2Config
import qualified Plutus.Contracts.V2.MarketplaceConfig as V2MarketConfig
import qualified Plutus.Contracts.V2.SimpleMarketplace as V2Simple
import qualified PlutusLedgerApi.V2 as PlutusV2
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

  writeArtifact outputDir "simple-market-v2.plutus" "SimpleMarketplaceV2" V2Simple.simpleMarketplacePlutusV2
  writeArtifact outputDir "simple-market-v2-superlazy.plutus" "SimpleMarketplaceV2SuperLazy" V2Simple.simpleMarketplacePlutusV2SuperLazy
  writeArtifact outputDir "market-config-v2.plutus" "MarketConfigV2" V2MarketConfig.marketConfigPlutusScript
  writeArtifact outputDir "market-config-v2-superlazy.plutus" "MarketConfigV2SuperLazy" V2MarketConfig.marketConfigPlutusScriptSuperLazy

  configV2 <- readScript @(PlutusScript PlutusScriptV2) (outputDir </> "market-config-v2.plutus")
  configV2SuperLazy <- readScript @(PlutusScript PlutusScriptV2) (outputDir </> "market-config-v2-superlazy.plutus")

  writeArtifact outputDir "configurable-market-v2.plutus" "ConfigurableMarketV2" (mkConfigurableMarketV2 configV2)
  writeArtifact outputDir "configurable-market-v2-superlazy.plutus" "ConfigurableMarketV2SuperLazy" (mkConfigurableMarketV2SuperLazy configV2SuperLazy)

writeArtifact :: HasTextEnvelope a => FilePath -> FilePath -> TextEnvelopeDescr -> a -> IO ()
writeArtifact outputDir fileName description value =
  BS.writeFile (outputDir </> fileName) $ prettyPrintJSON $ serialiseToTextEnvelope (Just description) value

readScript :: forall a. HasTextEnvelope a => FilePath -> IO a
readScript path = do
  result <- readFileTextEnvelope @a (File path)
  case result of
    Right value -> pure value
    Left err -> fail $ "Unable to load script artifact " ++ path ++ ": " ++ show err

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
