{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Cardano.Marketplace.V1.ServerRuntimeContext
where
import Data.Typeable
import Data.Maybe
import Data.Either
import Plutus.Contracts.V1.Marketplace (Market(Market, mTreasury, mPrimarySaleFee, mSecondarySaleFee, mOperator, mVersion), marketValidator, marketHundredPercent)
--import Plutus.Contracts.V1.Auction (auctionValidator, auctionHundredPercent)
import Cardano.Api
import Cardano.Kuber.Util
import qualified Data.Text as T
import System.Environment
import System.Directory (doesFileExist)
import Data.Functor ((<&>))
import Cardano.Kuber.Api
import qualified System.IO as IO
import Cardano.Marketplace.V1.RequestModels (addressParser)
import Text.Read (readMaybe)
import qualified Data.ByteString.Short as SBS
import qualified Data.ByteString.Lazy as LBS
import Cardano.Api.Shelley
import Codec.Serialise (serialise)
import Plutus.V1.Ledger.Api (unValidatorScript, PubKeyHash)
import GHC.Num (doubleFromInteger)
import Cardano.Kuber.Data.Parsers
import Plutus.Contracts.V1.Auction (auctionHundredPercent)

type ErrorMessage=String

data AuctionConfig = AuctionConfig {
  acFee:: Integer,
  acOperator:: PubKeyHash ,
  acTreasury :: PubKeyHash 
}

data RuntimeContext=RuntimeContext{
  runtimeContextCardanoConn :: DetailedChainInfo,
  runtimeContextMarket :: Market,
  runtimeContextAuctionConfig :: AuctionConfig,
  runtimeContextOperator :: AddressInEra BabbageEra,
  runtimeContextOperatorSkey :: SigningKey PaymentKey,
  runtimeContextTreasury :: AddressInEra BabbageEra
}

data ConigFromEnvOrSecretFile a = ConigFromEnvOrSecretFile {
   configEnvKey:: String,
   configFileLocationEnvKey:: Maybe String,
   configDefaultFile:: Maybe String,
   configDefaultValue :: Maybe String,
   parser :: String -> Maybe a
}

getLeft (Left e)  = [e]
getLeft (Right v) = []

populateTestnetConfig :: IO ()
populateTestnetConfig =do
  setEnv "MARKET_OPERATOR_ADDR" "addr_test1vzz6kpfgav34rzycphlnsuzfh8cyc094kl8s5wapyrqv7yghmdkuf"
  setEnv "MARKET_OPERATOR_SKEY" "{\
    \\"type\": \"PaymentSigningKeyShelley_ed25519\",\
    \\"description\": \"Payment Signing Key\",\
    \\"cborHex\": \"58207c44b4019a8975c01e8e39081d218023a8a5c722c36e44b4b08ce9313952c46e\"\
    \}"
  setEnv "TREASURY_ADDRESS" "addr_test1vzz6kpfgav34rzycphlnsuzfh8cyc094kl8s5wapyrqv7yghmdkuf"

resolveContext::  DetailedChainInfo -> IO ( Either [ErrorMessage] RuntimeContext)
resolveContext context = do
  populateTestnetConfig
  marketOperatorAddrEither  <- resolveEnv $ createEnvConfigNoDefault addressParser "MARKET_OPERATOR_ADDR"
  marketOperatorSkeyEither  <- resolveEnv $ createSecretConfigNoDefault  (parseSignKey . T.pack) "MARKET_OPERATOR_SKEY"
  treasuryAddressEither     <- resolveEnv $ createEnvConfigNoDefault  addressParser "TREASURY_ADDRESS"
  primarySaleFeeEither      <- resolveEnv $ createEnvConfigWithDefault  readDouble      "MARKET_PRIMARY_SALE_FEE" "5"
  auctionFeeEither          <- resolveEnv $ createEnvConfigWithDefault  readDouble      "AUCTION_FEE" "10"

  let errors =
            getLeft treasuryAddressEither
        ++  getLeft primarySaleFeeEither
        ++  getLeft marketOperatorSkeyEither
        ++ getLeft  auctionFeeEither
  if null errors then (do
      let primarySaleFee = floor $ forceRight primarySaleFeeEither * fromIntegral (marketHundredPercent `div` 100)
          operatorAddr =case marketOperatorAddrEither of
            Left s -> skeyToAddrInEra operatorSkey (getNetworkId context)
            Right aie ->aie
          operatorSkey = forceRight marketOperatorSkeyEither
          treasuryAddr = forceRight treasuryAddressEither
          auctionFee   = floor $ forceRight auctionFeeEither * fromIntegral (auctionHundredPercent `div` 100)
      operatorpkh <- addrInEraToPkh operatorAddr
      treasurypkh <- addrInEraToPkh treasuryAddr
      let market=Market{
                      mTreasury         = treasurypkh
                  ,   mOperator         = operatorpkh
                  ,   mPrimarySaleFee   = primarySaleFee
                  ,   mSecondarySaleFee = 2_500_000
                  ,   mVersion          = 21
                  }
      pure $ Right $ RuntimeContext{
                          runtimeContextCardanoConn = context,
                          runtimeContextMarket = market,
                          runtimeContextAuctionConfig =AuctionConfig{
                              acFee = auctionFee,
                              acOperator= operatorpkh,
                              acTreasury = treasurypkh
                          } ,
                          runtimeContextOperator=operatorAddr,
                          runtimeContextOperatorSkey=operatorSkey,
                          runtimeContextTreasury = treasuryAddr
      }) else pure $ Left errors
  where
    marketAddressShelley :: Market -> NetworkId -> Address ShelleyAddr
    marketAddressShelley market network = makeShelleyAddress network scriptCredential NoStakeAddress
      where
        scriptCredential=PaymentCredentialByScript marketHash
        marketScript= PlutusScript PlutusScriptV1  $ marketScriptPlutus market
        marketHash= hashScript   marketScript
        marketScriptPlutus market =PlutusScriptSerialised $ marketScriptBS market
        marketScriptBS market = SBS.toShort . LBS.toStrict $ serialise script
        script  = unValidatorScript $ marketValidator market
    forceRight (Right v) =  v
    forceRight _ =  error "Force Right failed it should not happen."
    fetchConfig= resolveEnv
    readDouble :: String -> Maybe Double
    readDouble = readMaybe
    addressParser = deserialiseAddress (AsAddressInEra AsBabbageEra) . T.pack


createEnvConfigNoDefault :: (String -> Maybe a)  -> String  -> ConigFromEnvOrSecretFile a
createEnvConfigNoDefault parser key= ConigFromEnvOrSecretFile key Nothing Nothing Nothing parser

createEnvConfigWithDefault :: (String -> Maybe a) -> String -> String -> ConigFromEnvOrSecretFile a
createEnvConfigWithDefault  parser key _default= ConigFromEnvOrSecretFile key Nothing Nothing (Just _default ) parser

createSecretConfigNoDefault ::(String -> Maybe a) ->  String  -> ConigFromEnvOrSecretFile a
createSecretConfigNoDefault  parser key = ConigFromEnvOrSecretFile key (Just $ key ++ "_FILE") Nothing Nothing  parser


-- too many alternatives in this function but all you 
-- need to know is that it will give appropriate error message  
-- or return the desired value. The string value will have to be parsed but it's fine.
resolveEnv :: ConigFromEnvOrSecretFile  a -> IO (Either ErrorMessage a)
resolveEnv (ConigFromEnvOrSecretFile key mFileKey defaultFile defaultValue parser) =do
  env <- doLookup  key
  case env of
    Nothing -> do
      case mFileKey of
        Nothing -> case defaultFile of
              Nothing -> pure $ returnDefault  $  key ++" environment variables not set. Default value is also not set"
              Just defaultFilePath ->
                returnFromFilePath
                    defaultFilePath
                    (pure $ returnDefault $ key ++" env missing, " ++defaultFilePath ++" file doesn't exist. Default value is not set.")
        Just fileKey -> do
          maybeFilePath <- doLookup fileKey
          case maybeFilePath of
            Nothing -> case defaultFile of
              Nothing -> pure $ returnDefault  $  key ++", "++fileKey ++" both environment variables not set. Default value is also not set"
              Just defaultFilePath ->
                returnFromFilePath
                    defaultFilePath
                    (pure $ returnDefault $ key ++" or "++fileKey ++"env missing, " ++defaultFilePath ++" file doesn't exist. Default value is not set.")
            Just filepath ->
              returnFromFilePath
                filepath
                (pure $ Left (fileKey ++ "=" ++ filepath ++ " is set : File doesn't exist"))

    Just v -> pure (case parser v of
       Nothing -> Left $ key  ++ ": `"++ v ++ "` cannot be parsed to requiredType "
       Just a -> Right  a)
  where
    returnFromFilePath path  _else =do
      exists<- doesFileExist  path
      if exists then IO.readFile path <&> (\x -> case parser x of
                                              Nothing -> Left ("File: "++path ++ "content couldn't be parsed for "++key)
                                              Just a -> Right a )
        else _else
    returnDefault msg= case defaultValue of
      Just v -> case parser v of
        Nothing -> Left  $ "Coding error: Hardcoded default value for " ++ key ++" Cann't be parsed"
        Just a -> Right a
      Nothing -> Left msg

    doLookup key = do
      env <- lookupEnv  key
      pure $ case env of
        Nothing -> Nothing
        Just v -> if null v then Nothing else env
