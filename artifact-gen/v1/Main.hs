{-# LANGUAGE OverloadedStrings #-}

module Main where

import Cardano.Api
import qualified Data.ByteString as BS
import qualified Plutus.Contracts.V1.SimpleMarketplace as V1Simple
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
  writeArtifact outputDir "simple-market-v1.plutus" "SimpleMarketplaceV1" V1Simple.simpleMarketplacePlutusV1
  writeArtifact outputDir "simple-market-v1-superlazy.plutus" "SimpleMarketplaceV1SuperLazy" V1Simple.simpleMarketplacePlutusV1SuperLazy

writeArtifact :: HasTextEnvelope a => FilePath -> FilePath -> TextEnvelopeDescr -> a -> IO ()
writeArtifact outputDir fileName description value =
  BS.writeFile (outputDir </> fileName) $ prettyPrintJSON $ serialiseToTextEnvelope (Just description) value
