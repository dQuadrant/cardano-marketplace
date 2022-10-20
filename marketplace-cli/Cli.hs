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
import Cardano.Kuber.Data.Parsers ( parseAssetNQuantity, parseScriptData, parseTxIn, parseValueText, scriptDataParser, parseAssetId, parseSignKey, parseAddressBench32, parseAddress)
import Cardano.Kuber.Util hiding (toHexString)
import Cardano.Ledger.Alonzo.Tx (TxBody (txfee))
import qualified Cardano.Ledger.BaseTypes as Shelley (Network (..))
import Cardano.Marketplace.Common.TextUtils
import Cardano.Marketplace.Common.TransactionUtils
import Cardano.Marketplace.V2.Core
import Codec.Serialise (serialise)
import Control.Exception (throwIO)
import Control.Monad (void)
import qualified Data.Aeson as Aeson
import qualified Data.ByteString.Builder as Text
import qualified Data.ByteString.Char8 as BS8
import qualified Data.ByteString as BS
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
import qualified Data.Text.IO as T

import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TL
import Plutus.Contracts.V2.SimpleMarketplace (SimpleSale (..), simpleMarketplacePlutusV2)
import qualified Plutus.Contracts.V2.SimpleMarketplace as SMP
import Plutus.V1.Ledger.Api (ToData (toBuiltinData), dataToBuiltinData)
import qualified Plutus.V1.Ledger.Api as Plutus
import System.Console.CmdArgs
import System.Directory (doesFileExist, getCurrentDirectory, getDirectoryContents)
import Cardano.Kuber.Console.ConsoleWritable
import Data.Text.Encoding (encodeUtf8)
import System.Directory.Internal.Prelude (getEnv)
import Plutus.V2.Ledger.Api (fromData, FromData (fromBuiltinData))
import qualified Data.Aeson as A
import qualified Data.Text.Lazy.IO as TL
import qualified Data.Text.Encoding as T
import Cardano.Api.SerialiseTextEnvelope (TextEnvelopeDescr(TextEnvelopeDescr))
import qualified Debug.Trace as Debug
import qualified Data.ByteString.Lazy.Char8 as BSL8

data Modes
  = Cat -- Cat script binary
  | Sell -- Sell item with cost on the market
      { item :: String, -- Asset to be placed on market <policyId.AssetName>
        cost :: Integer, -- cost in Lovelace
        addressSeller  :: Maybe Text, -- adddress OfSeller
        signingKeyFile :: String
      }
  | Buy -- Buy item from marketplace
      { txin :: Text, -- txin to buy from marketplace
        datum :: Maybe String, -- datum to buy from marketplace
        signingKeyFile :: String

      }
  | Withdraw -- Withdraw by the seller placed item from the marketplace
      { txin :: Text,
        datum :: Maybe String,
        signingKeyFile :: String
      }
  | Ls -- List utxos for market
  | Mint -- It mints a sample token 'testtoken' on the wallet
      {
        signingKeyFile :: String,
        assetName :: Text,
        amount :: Integer
      }
  | CreateCollateral -- Command for creating new collateral utxo containing 5 Ada
    {
      signingKeyFile :: String
    }
  | Balance -- Command for showing funds of the wallet
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
              addressSeller = def &= typ "PaymentReceivingAddress", 
              signingKeyFile = def &= typ "FilePath" &= name "signing-key-file"
            }
            &= help "Place an asset on sale Eg. sell 8932e54402bd3658a6d529da707ab367982ae4cde1742166769e4f94.Token \"2000000\"",
          Buy
            { txin = "" &= typ "TxIn" &= argPos 0,
              datum = Nothing &= typ "Datum",
              signingKeyFile = def &= typ "FilePath'" &= name "signing-key-file"
            }
            &= help "Buy an asset on sale after finiding out txIn from market-cli ls.  Eg. buy '8932e54402bd3658a6d529da707ab367982ae4cde1742166769e4f94#0' '{\"fields\":...}'",
          Withdraw
            { txin = "" &= typ "TxIn'" &= argPos 0,
              datum = Nothing &= typ "Datum'",
              signingKeyFile = def &= typ "'FilePath'" &= name "signing-key-file"
            }
            &= help "Withdraw an asset by seller after finiding out txIn from market-cli ls. Eg. buy '8932e54402bd3658a6d529da707ab367982ae4cde1742166769e4f94#0' '{\"fields\":...}'",
          Ls &= help "List utxos for market",
          Mint
            {
              assetName = "" &= typ "AssetName" &= argPos 0,
              amount = 1 &= typ "Amount" ,
              signingKeyFile = def &= typ "_FilePath" &= name "signing-key-file"
            }
          &= help "Mint a new asset",
          CreateCollateral
            {
              signingKeyFile = def &= typ "FilePath''" &= name "signing-key-file"
            }
          &= help "Create a new collateral utxo.",
          Balance
            {
              signingKeyFile = def &= typ "'FilePath''" &= name "signing-key-file"
            }
          &= help "Show funds of wallet."
        ]
        &= program "market-cli"
        &= summary "Cardano Marketplace CLI \nVersion 1.0.0.0"

  chainInfo <- chainInfoFromEnv
  let marketAddr = marketAddressShelley (getNetworkId chainInfo)
  case op of
    Ls -> do
      (UTxO uMap) <- queryMarketUtxos chainInfo marketAddr
      let vals = mapMaybe (\(txin,TxOut addr (TxOutValue _ val) datum _) -> case datum of
            TxOutDatumNone -> Nothing
            TxOutDatumHash sdsie ha -> Nothing
            TxOutDatumInline rtisidsie sd -> case fromBuiltinData $ dataToBuiltinData  $ toPlutusData sd of
              Nothing -> Nothing
              Just (SimpleSale artist cost) -> pure (txin,cost,val)  ) (Map.toList uMap)

      putStrLn $ "Market Address : " ++ T.unpack (serialiseAddress marketAddr)
      
      if null vals
        then putStrLn "Marketplace is Empty <> "
        else putStrLn $ "Market utxos:\n - " ++  intercalate "\n - "  (map (\(txin,cost,val)-> T.unpack (renderTxIn txin)  ++ "\t [Cost " ++ show (fromInteger cost/1e6) ++ "Ada] " ++  showVal val) vals)
      where
        showVal val= intercalate " +" $ map (\(AssetId pol (AssetName a),Quantity v) -> (if v>1 then show v ++ " " else "") ++ T.unpack (serialiseToRawBytesHexText pol) ++ "." ++ BS8.unpack a ) filtered
          where
            filtered= filter (\(a,v)-> a /= AdaAssetId )  $ valueToList val
    Cat -> do
      let envelope = serialiseToTextEnvelope (Just $  TextEnvelopeDescr "SimpleMarketplaceV2")  simpleMarketplacePlutusV2
      T.putStrLn $ T.decodeUtf8 $ prettyPrintJSON  envelope
    Sell itemStr cost saddressMaybe sKeyFile-> do
      sKey <- getSignKey sKeyFile
      sellerAddress <-case saddressMaybe of
        Nothing -> pure Nothing
        Just txt -> do 
          addr<- parseAddress txt
          pure $ pure addr
      sellToken chainInfo itemStr cost sKey sellerAddress marketAddr
    Buy txInText datumStr sKeyFile-> do
      sKey <- getSignKey sKeyFile
      buyToken chainInfo txInText datumStr sKey marketAddr
    Withdraw txInText datumStr sKeyFile-> do
      sKey <- getSignKey sKeyFile
      withdrawToken chainInfo txInText datumStr sKey marketAddr
    Mint sKeyFile tokenNameStr qty-> do
      asset <- case deserialiseFromRawBytes AsAssetName $ encodeUtf8 tokenNameStr of
          Nothing -> throwIO $ FrameworkError ParserError ("Invalid assetName string : "++ T.unpack  tokenNameStr)
          Just an -> pure an
      skey <- getSignKey sKeyFile
      mint chainInfo skey (skeyToAddrInEra skey (getNetworkId chainInfo)) asset qty
    CreateCollateral sKeyFile-> do
      skey <- getSignKey sKeyFile
      let addrInEra = getAddrEraFromSignKey chainInfo skey
      utxosE <- queryAddressInEraUtxos (getConnectInfo chainInfo) [addrInEra]
      utxos <- case utxosE of
        Left fe -> error $ "Error querying utxos: " <> show fe
        Right utxos -> pure utxos
      let txOperations = txPayTo addrInEra (lovelaceToValue $ Lovelace 60_000_000) 
            <> txWalletAddress addrInEra 
            <> txConsumeUtxos utxos
            <> txWalletSignKey skey
      submitTransaction chainInfo txOperations 
    Balance sKeyFile-> do
      if null sKeyFile
        then fail "Missing filename"
        else pure ()
      skey <- getSignKey sKeyFile
      let addrInEra = getAddrEraFromSignKey chainInfo skey
      putStrLn $ "Wallet Address: " ++ T.unpack (serialiseAddress addrInEra)
      utxosE <- queryAddressInEraUtxos (getConnectInfo chainInfo) [addrInEra]
      case utxosE of
        Left fe -> throwIO $ FrameworkError ParserError (show fe)
        Right utxos -> putStrLn $ jsonEncodeUtxos utxos