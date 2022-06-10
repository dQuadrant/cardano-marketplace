{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Cli where

import Cardano.Api
import Cardano.Api.Byron (Address (ByronAddress))
import Cardano.Api.Shelley (Address (ShelleyAddress), AsType (AsAlonzoEra), Lovelace (Lovelace), ProtocolParameters, fromPlutusData, fromShelleyStakeReference, scriptDataToJsonDetailedSchema, shelleyPayAddrToPlutusPubKHash, toPlutusData, toShelleyStakeAddr, toShelleyStakeCredential)
import qualified Cardano.Api.Shelley as Shelley
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers (parseAssetIdText, parseAssetNQuantity, parseScriptData, parseTxIn, parseValueText, scriptDataParser)
import Cardano.Kuber.Util hiding (toHexString)
import Cardano.Ledger.Alonzo.Tx (TxBody (txfee))
import qualified Cardano.Ledger.BaseTypes as Shelley (Network (..))
import Cardano.Marketplace.Common.TextUtils
import Cardano.Marketplace.Common.TransactionUtils
import Cardano.Marketplace.V1.Core
import Codec.Serialise (serialise)
import Control.Exception (throwIO)
import Control.Monad (void)
import qualified Data.Aeson as Aeson
import qualified Data.ByteString.Builder as Text
import qualified Data.ByteString.Char8 as BS8
import Data.ByteString.Lazy.Char8 (toStrict)
import Data.Char (toLower)
import Data.Data (Data, Typeable)
import Data.Functor ((<&>))
import Data.List (intercalate, isSuffixOf, sort)
import qualified Data.Map as Map
import Data.Maybe (fromMaybe, mapMaybe)
import qualified Data.Set as Set
import Data.Text (Text, strip)
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TL
import Plutus.Contracts.V1.SimpleMarketplace (SimpleSale (..), simpleMarketplacePlutus)
import qualified Plutus.Contracts.V1.SimpleMarketplace as SMP
import Plutus.V1.Ledger.Api (ToData (toBuiltinData))
import qualified Plutus.V1.Ledger.Api as Plutus
import System.Console.CmdArgs
import System.Directory (doesFileExist, getCurrentDirectory, getDirectoryContents)
import Cardano.Kuber.Console.ConsoleWritable
import Data.ByteString.Char8 (ByteString)

data Modes
  = Cat -- Cat script binary
  | Sell -- Sell item with cost on the market
      { item :: String, -- Asset to be placed on market <policyId.AssetName>
        cost :: Integer, -- cost in Lovelace
        signingKeyFile :: String
      }
  | Buy -- Buy item from marketplace
      { txin :: Text, -- txin to buy from marketplace
        datum :: String, -- datum to buy from marketplace
        signingKeyFile :: String

      }
  | Withdraw -- Withdraw by the seller placed item from the marketplace
      { txin :: Text,
        datum :: String,
        signingKeyFile :: String
      }
  | Ls -- List utxos for market
  | Mint -- It mints a sample token 'testtoken' on the wallet
      { 
        signingKeyFile :: String,
        assetName :: String,
        amount :: Integer
      }
  | CreateCollateral -- Command for creating new collateral utxo containing 5 Ada
    {
      signingKeyFile :: String
    }
  deriving (Show, Data, Typeable)

runCli :: IO ()
runCli = do
  op <-
    cmdArgs $
      modes
        [ Cat &= help "Cat script binary",
          Sell
            { item = def &= typ "Asset" &= argPos 0,
              cost = def &= typ "Price" &= argPos 1,
              signingKeyFile = def &= typ "FilePath" &= name "signing-key-file"
            }
            &= help "Place an asset on sale Eg. sell 8932e54402bd3658a6d529da707ab367982ae4cde1742166769e4f94.Token \"2000000\"",
          Buy
            { txin = "" &= typ "TxIn" &= argPos 0,
              datum = "" &= typ "Datum" &= argPos 1,
              signingKeyFile = def &= typ "FilePath'" &= name "signing-key-file"
            }
            &= help "Buy an asset on sale after finiding out txIn from market-cli ls.  Eg. buy '8932e54402bd3658a6d529da707ab367982ae4cde1742166769e4f94#0' '{\"fields\":...}'",
          Withdraw
            { txin = "" &= typ "TxIn'" &= argPos 0,
              datum = "" &= typ "Datum'" &= argPos 1,
              signingKeyFile = def &= typ "'FilePath'" &= name "signing-key-file"
            }
            &= help "Withdraw an asset by seller after finiding out txIn from market-cli ls. Eg. buy '8932e54402bd3658a6d529da707ab367982ae4cde1742166769e4f94#0' '{\"fields\":...}'",
          Ls &= help "List utxos for market",
          Mint 
            {
              assetName = "" &= typ "AssetName" &= argPos 0,
              amount = def &= typ "Amount" &= argPos 1,
              signingKeyFile = def &= typ "'FilePath" &= name "signing-key-file"
            }
          &= help "Mint a new asset for testing purposes.",
          CreateCollateral 
            {
              signingKeyFile = def &= typ "FilePath''" &= name "signing-key-file"
            }
          &= help "Create a new collateral utxo."
        ]
        &= program "market-cli"
        &= summary "Cardano Marketplace CLI \nVersion 1.0.0.0"

  ctx <- chainInfoFromEnv
  let marketAddr = marketAddressShelley (getNetworkId ctx)
  case op of
    Ls -> do
      utxos <- queryMarketUtxos ctx marketAddr
      putStrLn $ "Market Address : " ++ T.unpack (serialiseAddress marketAddr)
      putStrLn $ toConsoleText "  " utxos
    Cat -> do
      let scriptInCbor = serialiseToCBOR simpleMarketplacePlutus
      putStrLn $ toHexString scriptInCbor
    Sell itemStr cost sKeyFile-> do
      sKey <- readSignKey sKeyFile
      sellToken ctx itemStr cost sKey marketAddr
    Buy txInText datumStr sKeyFile-> do
      sKey <- readSignKey sKeyFile
      buyToken ctx txInText datumStr sKey marketAddr
    Withdraw txInText datumStr sKeyFile-> do
      sKey <- getDefaultSignKey
      withdrawToken ctx txInText datumStr sKey marketAddr
    Mint sKeyFile assetName amount-> do
      let assetNameBs = BS8.pack assetName
      skey <- readSignKey sKeyFile
      mint ctx skey assetNameBs amount
    CreateCollateral sKeyFile-> do
      skey <- readSignKey sKeyFile
      let addrInEra = getAddrEraFromSignKey ctx skey
          txOperations = txPayTo addrInEra (lovelaceToValue $ Lovelace 5_000_000) <> txWalletAddress addrInEra  
      submitTransaction ctx txOperations skey
    
