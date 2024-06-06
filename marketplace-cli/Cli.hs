{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE LambdaCase #-}

module Cli where

import Cardano.Api
import Cardano.Api.Byron (Address (ByronAddress))
import Cardano.Api.Shelley (Address (ShelleyAddress), AsType (AsAlonzoEra), ProtocolParameters, fromPlutusData, fromShelleyStakeReference, scriptDataToJsonDetailedSchema, shelleyPayAddrToPlutusPubKHash, toPlutusData, toShelleyStakeAddr, toShelleyStakeCredential)
import qualified Cardano.Api.Shelley as Shelley
import Cardano.Kuber.Api
import Cardano.Kuber.Data.Parsers ( parseAssetNQuantity, parseScriptData, parseTxIn, parseValueText, scriptDataParser, parseAssetId, parseSignKey, parseAddress, parseAssetName)
import Cardano.Kuber.Util hiding (toHexString)
import qualified Cardano.Ledger.BaseTypes as Shelley (Network (..))
import Cardano.Marketplace.Common.TextUtils
import Cardano.Marketplace.Common.TransactionUtils
    ( getSignKey,
      getTxIdFromTx,
      marketAddressInEra,
      marketAddressShelley )
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

import System.Console.CmdArgs
import System.Directory (doesFileExist, getCurrentDirectory, getDirectoryContents)
import Cardano.Kuber.Console.ConsoleWritable
import Data.Text.Encoding (encodeUtf8)
import qualified Data.Aeson as A
import qualified Data.Text.Lazy.IO as TL
import qualified Data.Text.Encoding as T
import qualified Debug.Trace as Debug
import qualified Data.ByteString.Lazy.Char8 as BSL8
import PlutusLedgerApi.V2 (dataToBuiltinData, FromData (fromBuiltinData))

data Modes
  = Cat -- Cat script binary
  | Sell -- Sell item with cost on the market
      { item :: T.Text, -- Asset to be placed on market <policyId.AssetName>
        cost :: Integer, -- cost in Lovelace
        addressSeller  :: Maybe Text, -- adddress OfSeller
        signingKeyFile :: String
      }
  | Buy -- Buy item from marketplace
      { txin :: Text, -- txin to buy from marketplace
        datum :: Maybe String, -- datum to buy from marketplace
        signingKeyFile :: String,
        address:: Maybe T.Text
      }
  | Withdraw -- Withdraw by the seller placed item from the marketplace
      { txin :: Text,
        datum :: Maybe String,
        signingKeyFile :: String,
        address:: Maybe T.Text

      }
  | Ls -- List utxos for market
  | Mint -- It mints a sample token 'testtoken' on the wallet
      {
        signingKeyFile :: String,
        mintWalletAddr :: Text,
        assetName :: Text,
        amount :: Integer
      }
  | CreateCollateral -- Command for creating new collateral utxo containing 5 Ada
    {
      signingKeyFile :: String,
      address:: Maybe T.Text

    }
  | Balance -- Command for showing funds of the wallet
    {
      signingKeyFile :: String,
      address:: Maybe T.Text
    }
  deriving (Show, Data, Typeable)

runCli :: IO ()
runCli = do
  op <-
    cmdArgs $
      modes
        [ Cat &= help "Cat script binary",
          Sell
            { item = "" &= typ "Asset" &= argPos 0,
              cost = def &= typ "Price" &= argPos 1,
              addressSeller = def &= typ "PaymentReceivingAddress", 
              signingKeyFile = def &= typ "FilePath" &= name "signing-key-file"
            }
            &= help "Place an asset on sale Eg. sell 8932e54402bd3658a6d529da707ab367982ae4cde1742166769e4f94.Token \"2000000\"",
          Buy
            { txin = "" &= typ "TxIn" &= argPos 0,
              datum = Nothing &= typ "Datum",
              signingKeyFile = def &= typ "FilePath'" &= name "signing-key-file",
              address = def  &=typ "WalletAddress" &=name "address"
            }
            &= help "Buy an asset on sale after finiding out txIn from market-cli ls.  Eg. buy '8932e54402bd3658a6d529da707ab367982ae4cde1742166769e4f94#0' '{\"fields\":...}'",
          Withdraw
            { txin = "" &= typ "TxIn'" &= argPos 0,
              datum = Nothing &= typ "Datum'",
              signingKeyFile = def &= typ "'FilePath'" &= name "signing-key-file",
              address = def  &=typ "WalletAddress" &=name "address"
            }
            &= help "Withdraw an asset by seller after finiding out txIn from market-cli ls. Eg. buy '8932e54402bd3658a6d529da707ab367982ae4cde1742166769e4f94#0' '{\"fields\":...}'",
          Ls &= help "List utxos for market",
          Mint
            {
              assetName = "" &= typ "AssetName" &= argPos 0,
              amount = 1 &= typ "Amount" &= argPos 1 ,
              signingKeyFile = def &= typ "_FilePath" &= name "signing-key-file",
              mintWalletAddr = ""  &=typ "WalletAddress" &=name "address"
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
              , address = def &= typ "WalletAddress" &= name "address"
            }
          &= help "Show funds of wallet."
        ]
        &= program "market-cli"
        &= summary "Cardano Marketplace CLI \nVersion 1.0.0.0"

  chainInfo <- chainInfoFromEnv
  networkId <- evaluateKontract chainInfo kGetNetworkId >>= throwFrameworkError
  let marketAddr = marketAddressShelley networkId

  case op of
    Ls -> runKontract chainInfo $  do
      (UTxO uMap) <- kQueryUtxoByAddress  $ Set.singleton ( toAddressAny marketAddr)
      let vals = mapMaybe (\(txin,TxOut addr val datum _) -> case datum of
            TxOutDatumNone -> Nothing
            TxOutDatumHash sdsie ha -> Nothing
            TxOutDatumInline rtisidsie sd -> case fromBuiltinData $  dataToBuiltinData $  toPlutusData $ getScriptData  sd of
              Nothing -> Nothing
              Just (SimpleSale artist cost) -> pure (txin,cost,val)  ) (Map.toList uMap)

      liftIO $ do
        putStrLn $ "Market Address : " ++ T.unpack (serialiseAddress marketAddr)

        if null vals
          then putStrLn "Marketplace is Empty <> "
          else putStrLn $ "Market utxos:\n - " 
            ++  intercalate 
                "\n - "  
                (map (\(txin,cost,val :: TxOutValue ConwayEra )-> T.unpack (renderTxIn txin)  
                           ++ "\t [Cost " ++ show (fromInteger cost/1e6) ++ "Ada] " ++  showVal (txOutValueToValue val)) vals)
      where
        showVal val= intercalate " +" $ map (\(AssetId pol (AssetName a),Quantity v) -> (if v>1 then show v ++ " " else "") ++ T.unpack (serialiseToRawBytesHexText pol) ++ "." ++ BS8.unpack a ) filtered
          where
            filtered= filter (\(a,v)-> a /= AdaAssetId )  $ valueToList val
    Cat -> do
      let envelope = serialiseToTextEnvelope (Just $   "SimpleMarketplaceV2")  simpleMarketplacePlutusV2
      T.putStrLn $ T.decodeUtf8 $ prettyPrintJSON  envelope
    Sell itemStr cost saddressMaybe sKeyFile-> do
      sKey <- getSignKey sKeyFile
      sellVale <- parseAssetNQuantity itemStr
      sellerAddress <- case saddressMaybe of
        Nothing -> pure  $ skeyToAddrInEra sKey networkId 
        Just txt -> parseAddress txt
      let txBuilder
            = sellBuilder  (marketAddressInEra networkId)  (valueFromList [sellVale]) cost  sellerAddress 
              <> txWalletSignKey sKey
              <> txWalletAddress sellerAddress
      runKontract chainInfo $ runBuildAndSubmit txBuilder 
        
    Buy txInText datumStr sKeyFile addrMaybe-> do
      sKey <- getSignKey sKeyFile
      tin <- parseTxIn txInText
      address <- getAddress networkId sKey addrMaybe
      runKontract  chainInfo $ do
        buyBuilder <- buyTokenBuilder tin
        let builder = buyBuilder
                        <> txWalletSignKey sKey
                        <> txWalletAddress address
        runBuildAndSubmit builder
 
    Withdraw txInText datumStr sKeyFile mAddr-> do
      sKey <- getSignKey sKeyFile
      txIn <- parseTxIn txInText
      address <- getAddress networkId sKey mAddr
      runKontract  chainInfo $ do
        withdrawBuilder <- withdrawTokenBuilder txIn
        let builder = withdrawBuilder
                        <> txWalletSignKey sKey
                        <> txWalletAddress address
        runBuildAndSubmit builder

    Mint sKeyFile walletAddrStr tokenNameStr qty-> runKontract chainInfo $  do
      assetName <- kWrapParser $ parseAssetName tokenNameStr
      builderWallet <- if T.null walletAddrStr 
                then  pure mempty
                else   kWrapParser $ parseAddress walletAddrStr
                      <&> txWalletAddress
      skey <- liftIO $ readSignKey sKeyFile
      kBuildAndSubmit $ 
        txWalletSignKey skey
        <> builderWallet
        <> mint  (getVerificationKey $ skey)  assetName qty

    CreateCollateral sKeyFile mAddr-> do
      skey <- getSignKey sKeyFile
      addrInEra <- getAddress networkId  skey mAddr
      let txOperations = txPayTo addrInEra (valueFromList [(AdaAssetId,Quantity 5_000_000)]) 
            <> txWalletAddress addrInEra 
            <> txWalletSignKey skey
      runKontract chainInfo $ do 
        runBuildAndSubmit txOperations
 
    Balance sKeyFile addrStr -> do
      walletAddr :: AddressInEra ConwayEra <- case addrStr of 
          Nothing ->  do 
            if null sKeyFile
              then fail "Missing filename"
              else pure ()
            skey <- getSignKey sKeyFile
            pure $ skeyToAddrInEra  skey networkId
          Just addr  -> 
            parseAddress addr

      putStrLn $ "Wallet Address: " ++ T.unpack (serialiseAddress walletAddr)
      runKontract chainInfo $ do 
          utxos :: UTxO ConwayEra <- kQueryUtxoByAddress (Set.singleton $ addressInEraToAddressAny walletAddr)
          liftIO $ putStrLn $ toConsoleText " - " utxos


runBuildAndSubmit :: (HasKuberAPI api, HasSubmitApi api) => TxBuilder -> Kontract api w FrameworkError ()
runBuildAndSubmit   txBuilder =  do 
        tx<- kBuildTx txBuilder
        liftIO $ putStrLn $ "Tx Created :" ++  (getTxIdFromTx tx)

        kSubmitTx (InAnyCardanoEra ConwayEra tx)
        liftIO $ putStrLn $ "Tx Submitted :" ++  (getTxIdFromTx tx)


getAddress ::MonadFail m => NetworkId ->  SigningKey PaymentKey -> Maybe Text -> m (AddressInEra ConwayEra)
getAddress netId skey mAddr = case mAddr of 
  Just addrTxt -> parseAddress addrTxt
  Nothing -> pure $ skeyToAddrInEra skey netId

runKontract :: api -> Kontract api w FrameworkError v-> IO ()
runKontract api  c = do 
    evaluateKontract api  c
     >>= \case
        Left e -> putStrLn $ show e
        _ -> pure ()
