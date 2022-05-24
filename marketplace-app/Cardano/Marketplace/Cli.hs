{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE GADTs #-}
module Cardano.Marketplace.Cli
where
import Data.Data ( Data, Typeable )
import System.Console.CmdArgs
import Cardano.Marketplace.Server (startMarketServer)
import Cardano.Kuber.Api
import Cardano.Marketplace.V1.RequestModels
import Cardano.Kuber.Util
import Cardano.Marketplace.V1.Core
import qualified Data.Text as T
import Cardano.Marketplace.Common.ConsoleWritable
import Data.Functor ((<&>))
import Cardano.Api.Shelley (AsType(AsAlonzoEra), Lovelace (Lovelace), Address (ShelleyAddress), fromShelleyStakeReference, toShelleyStakeCredential, toShelleyStakeAddr, fromPlutusData)
import qualified Data.Map as Map
import Control.Monad (void)
import Data.Text(Text, strip)
import Cardano.Api
import Cardano.Marketplace.V1.ServerRuntimeContext
import Data.List (intercalate, isSuffixOf, sort)
import System.Directory (doesFileExist, getCurrentDirectory, getDirectoryContents)
import Data.Maybe (mapMaybe)
import Data.Char (toLower)
import Cardano.Api.Byron (Address(ByronAddress))
import qualified Cardano.Ledger.BaseTypes as Shelley (Network(..))
import Plutus.Contracts.V1.Marketplace (marketScript, DirectSale (..))
import qualified Plutus.Contracts.V1.Marketplace as DirectSale
import qualified Plutus.Contracts.V1.Auction as Auction
import Codec.Serialise (serialise)
import Cardano.Ledger.Alonzo.Tx (TxBody(txfee))
import Plutus.V1.Ledger.Api (ToData(toBuiltinData), toData)
import Cardano.Marketplace.Common.TextUtils
import Cardano.Kuber.Data.Parsers (parseAssetNQuantity, parseScriptData, parseAssetIdText, parseValueText)
data Modes =
      Cat {
        item:: String
      }
      |
      Sell {
          item:: String,
          cost :: String
        }
      | Ls
      | Pay {
        receiver :: String,
        value :: String,
        changeAddress :: String
      }
      | MoveFunds {
        valReceiver :: String
      }
      | UtxoSplit {
          assetToSplit :: String,
          count :: String
        }
      | Buy {
        asset :: Text,
        datum:: Text
      }
      | Utxos {
        address:: String
       }
      | Balance {
          address:: String
        }
      | Withdraw {
        utxoId:: Text
        }
      | Keygen {
        keyfile:: String
      }
      | Wallet {cmd :: String, val :: String}
      | Server
      | AddrInfo {
        address :: String
      } deriving (Show, Data, Typeable)

runCli :: IO ()
runCli = do
  op <- cmdArgs $ modes [
        Server
      , Pay {
            receiver = def &=typ "(Receiver Address)" &=argPos 0,
            value = def &=typ "Value" &=argPos 1,
            changeAddress = def &=typ "(Change Address)"
          } &=details ["Pay value to an address "]
      , MoveFunds {
        valReceiver = def &=typ "(Receiver Address)" &=argPos 0
      },
      AddrInfo {
        address = def &=typ "Address" &=argPos 0
      }
      , Buy {
        asset= "" &=typ "AssetId",
        datum = "" &=typ "Datum" &=argPos 0
      },
      UtxoSplit {
          count= def &=typ "Count" &=argPos 0 ,
          assetToSplit = def &= typ "Asset" &=args
        }
      , Sell {
            item=def &=  typ "Asset" &=argPos 0,
            cost= def &=typ "Price" &=argPos 1
          } &=details ["  Place an asset on sale", "  Eg. sell 8932e54402bd3658a6d529da707ab367982ae4cde1742166769e4f94.Token \"2Ada\""]
      , Ls
      , Balance {
        address =def &=typ "Address" &= args
      },
      Wallet{
          cmd = def &=typ "switch|create|ls" &=argPos 0
        , val = def &=typ "CommandValue" &=args
      }
      , 
      -- Withdraw {
      --   utxoId = "" &= typ "UtxoId" &=args
      -- }
      -- , 
      Utxos {
        address =def &=typ "Address" &= args
      },
      Keygen{
        keyfile = def &=typ "UtxoId" &=args
      },
      Cat{
        item = def &=typ "script|key" &=argPos 0
      }
    ]&=program "market-cli"
  case op of
    Cat item -> do
      eCtx <- resolveContext
      case eCtx of
        Left ss ->  putStrLn $ "RuntimeConfigurationError:\n - " ++ intercalate "\n - "  ss
        Right (RuntimeContext ctx market aConfig operatorAddr operatorSkey treasuryAddr)-> do
          case map toLower  item of
            "script"  -> do
              let marketScript = marketScriptPlutus   market
              let bs = serialiseToCBOR marketScript
              putStrLn $ toHexString bs
            "key" -> do
              skey<- getCurrentSkey
              let encoded=serialiseToBech32  skey
              putStrLn $ "Bench32 : " ++  T.unpack encoded
              putStrLn $ "RawHex  : " ++ T.unpack (serialiseToRawBytesHexText  skey)
            "redeemers" -> do 
              putStrLn $ "Buy              : " ++ dataumStringJson ( fromPlutusData $ toData $  toBuiltinData  DirectSale.Buy )
              putStrLn $ "Withdraw         : " ++ dataumStringJson (fromPlutusData $ toData $ toBuiltinData DirectSale.Withdraw) 
              putStrLn $ "Bid              : " ++ dataumStringJson  (fromPlutusData $ toData $ toBuiltinData Auction.Bid)
              putStrLn $ "Cancel Auction   : " ++ dataumStringJson  (fromPlutusData $ toData $ toBuiltinData Auction.Withdraw)
              putStrLn $ "Finalize Auction : " ++ dataumStringJson  (fromPlutusData $ toData $ toBuiltinData Auction.ClaimBid )
            _         -> do
              putStrLn  " Invalid option provided to cat command"

    -- AddrInfo addr ->do
    --   if null addr
    --     then
    --     putStrLn  "Usage: addrinfo address"
    --     else
    --       case deserialiseAddress (AsAddressInEra AsAlonzoEra ) (T.pack addr) of
    --         Nothing -> fail "Weird address"
    --         Just aie -> do
    --             putStrLn $ "Address                  : " ++ addr
    --             case aie of { AddressInEra atie ad -> case ad of
    --                   ByronAddress ad' -> putStrLn "Address type: ByronAddress"
    --                   ShelleyAddress net cre sr -> do
    --                     putStrLn    "Address type             : Shelley"
    --                     case addrToMaybePkh ad of
    --                       Nothing -> pure () 
    --                       Just pkh -> putStrLn $ "PubKeyHash               : " ++  show pkh
    --                     let unstakedAddr = unstakeAddr aie
    --                         network      =case net of
    --                           Shelley.Testnet  -> Testnet (NetworkMagic 1097911063)
    --                           Shelley.Mainnet -> Mainnet
    --                     case fromShelleyStakeReference sr of
    --                           StakeAddressByValue sc ->do
    --                             putStrLn $  "Address without stakeKey : " ++ T.unpack (serialiseAddress unstakedAddr)
    --                             putStrLn  $ "StakeAddress             : " ++  T.unpack ( serialiseAddress $ makeStakeAddress   network   sc)
    --                             putStrLn $  "Stake Key Hash           : " ++ show sc
    --                           StakeAddressByPointer sap -> do
    --                             putStrLn $  "Address without stakeKey : " ++ T.unpack (serialiseAddress unstakedAddr)
    --                             putStrLn $  "StakePointer             : " ++ show sap
    --                           NoStakeAddress -> putStrLn "Staking not enabled"
    --                     }
    
    Sell itemStr costStr -> do
      eCtx <- resolveContext
      case eCtx of
        Left ss ->  putStrLn $ "RuntimeConfigurationError:\n - " ++ intercalate "\n - "  ss
        Right (RuntimeContext ctx market aConfig operatorAddr operatorSkey treasuryAddr)-> do
        item <-parseAssetNQuantity $ T.pack itemStr
        print item

        cost <- parseAssetNQuantity $ T.pack costStr
        sKey <-getCurrentSkey
        let model = SellReqBundle (TxContextAddressesReq (Just sKey) Nothing Nothing Nothing Nothing Map.empty)  [SellReqModel{
               sreqParties =[],
              sreqAsset =CostModal item,
              sreqCost= CostModal cost,
              isSecondary = False
        }] True 
        SaleCreateResponse  tx datums _<- placeOnMarket ctx market model
        submitTx ctx (SubmitTxModal tx  Nothing )
        putStrLn $ "Submited Tx :"++ tail (init $ show $ getTxId $ getTxBody  tx)
        putStrLn $ "Datum       :" ++  dataumStringJson (head  datums)
    Buy assetId datum -> do
      eCtx <- resolveContext
      case eCtx of
        Left ss ->  putStrLn $ "RuntimeConfigurationError:\n - " ++ intercalate "\n - "  ss
        Right (RuntimeContext ctx market aConfig operatorAddr operatorSkey treasuryAddr) ->do
          scriptData <- parseScriptData datum
          let dataHash=show $ hashScriptData scriptData
          signKey<- getCurrentSkey
          asset <- parseAssetIdText assetId
          let modal = BuyReqModel{
                  buyReqContext = TxContextAddressesReq (Just signKey) Nothing Nothing Nothing Nothing Map.empty ,
                  byReqSellerDepositSkey = Nothing,
                  buyReqUtxo = Nothing,
                  buyReqAsset=  Just  asset,
                  buyReqDatum=scriptData,
                  buyCollateral= Nothing -- use specific address as collateral, if not present, a suitable collateral will be choosen. 
              }
          putStrLn $ "DatumHash :" ++ dataHash
          (TxResponse  tx datums ) <- buyToken ctx market modal
          putStrLn $ "Submited Tx :"++ tail (init $ show $ getTxId $ getTxBody tx)
    -- Withdraw assetid -> do
    --   eCtx <- resolveContext
    --   case eCtx of
    --     Left ss ->  putStrLn $ "RuntimeConfigurationError:\n - " ++ intercalate "\n - "  ss
    --     Right rCtx-> do
    --       let (RuntimeContext ctx aConfig market  operatorAddr operatorSkey treasuryAddr)= rCtx
    --       skey <- getCurrentSkey
    --       scriptData <- parseScriptData assetid
    --       let modal = WithdrawReqModel{
    --           withdrawDatum=scriptData,
    --           withdrawUtxo=Nothing,
    --           withdrawAddress=Nothing,
    --           withdrawAsset=Nothing,
    --           withdrawCollateral=Nothing
    --         }
    --       TxResponse tx datums <-withdrawCommand rCtx  modal
    --       putStrLn $ "Submited Tx :"++ tail (init $ show $ getTxId $ getTxBody tx)
    --       putStrLn "Done"

    Ls -> do
      eCtx <- resolveContext
      case eCtx of
        Left ss ->  putStrLn $ "RuntimeConfigurationError:\n - " ++ intercalate "\n - "  ss
        Right (RuntimeContext ctx market aConfig operatorAddr operatorSkey treasuryAddr)-> do
        let addr=marketAddressShelley market  (getNetworkId ctx)
        utxos <- queryMarketUtxos  ctx market
        putStrLn $ "Market Address : " ++ T.unpack (serialiseAddress addr)
        putStrLn $ toConsoleText  "  "  utxos
    MoveFunds receiver-> do
      fail "Work in progress"
      ctx <- chainInfoFromEnv
      receiverAddress <- case deserialiseAddress (AsAddressInEra AsAlonzoEra) (T.pack  receiver) of
        Just addr -> pure addr
        Nothing  ->  fail "Invalid receiver address"
      skey <- getCurrentSkey
      utxos <- queryUtxosOf ctx (AddressModal receiverAddress)
      let txOperation= txConsumeUtxos utxos
      fail "done"
    Pay receiver value changeAddress -> do
      ctx <- chainInfoFromEnv >>= withDetails
      receiverAddress <- case deserialiseAddress (AsAddressInEra AsAlonzoEra) (T.pack  receiver) of
        Just addr -> pure addr
        Nothing  ->  fail "Invalid receiver address"
      skey <- getCurrentSkey
      val <- parseValueText $ T.pack value

      TxResponse tx datums <-payToAddress ctx (PaymentReqModel{
          preqSkey=skey,
          preqReceivers =[PaymentUtxoModel{
              paymentValue =  val,
              receiverAddress = receiverAddress,
              deductFees = False, -- pay this address paymentValue -txFee.
              addChange = False
          } ],
          preqChangeAddress =Nothing,
          preqPayerAddress=Nothing,
          spendEverything= False,
          ignoreTinySurplus = False, -- if value < minUtxoLovelace remains as change, send it to the receiver.
          ignoreTinyInsufficient = False
      })
      submitTx ctx (SubmitTxModal tx Nothing)
      putStrLn $ "Submited Tx :"++ tail (init $ show $ getTxId $ getTxBody tx)

    Balance addr ->do
      ctx <- chainInfoFromEnv
      if map toLower  addr == "all"
        then fail "not implemented"
        else do
          addr <- if null addr
            then  do
              (wallet,skey)<- getCurrentWallet
              let addr=skeyToAddrInEra  skey (getNetworkId ctx)
              putStrLn $ "Wallet Address :  " ++ T.unpack (serialiseAddress addr)
              putStrLn $ "Wallet Name    :  " ++  wallet

              pure addr
            else case deserialiseAddress (AsAddressInEra AsAlonzoEra) (T.pack addr) of
                    Nothing -> fail $ "Conversion of address to AlonzoAddress failed: "++addr
                    Just aie -> pure aie
          utxos <- queryUtxosOf ctx (AddressModal addr )
          let balance=utxoSum utxos
              utxoCount=case utxos of { UTxO map -> Map.size  map }
          putStrLn $      "Utxo Count     :  " ++ show utxoCount
          putStrLn $ toConsoleText "  " balance
    Utxos addr -> do
      ctx <- chainInfoFromEnv
      addr <- if null addr
        then  do
          addr <- getCurrentSkey <&> flip  skeyToAddrInEra (getNetworkId ctx)
          putStrLn $ "Wallet Address :  " ++ T.unpack (serialiseAddress addr)
          pure addr
        else case deserialiseAddress (AsAddressInEra AsAlonzoEra) (T.pack addr) of
                Nothing -> fail $ "Conversion of address to AlonzoAddress failed: "++addr
                Just aie -> pure aie
      utxos <- queryUtxosOf ctx (AddressModal addr)
      putStrLn $ toConsoleText  "  "  utxos
    Server ->startMarketServer

    Wallet cmd val -> case cmd of
          "switch" -> do
            if not $ null val
              then  do
              file <- getWorkPath [val ++ ".skey"]
              exists <- doesFileExist file
              if not exists
                then
                  putStrLn $ "Error : Wallet file doesn't exist : " ++ file
                else do
                  ctx <- chainInfoFromEnv
                  skey <- readSignKey file
                  file <- getWorkPath ["skey.default"]
                  writeFile file val
                  let address= skeyToAddrInEra skey (getNetworkId ctx)
                  utxos <- queryUtxosOf ctx (AddressModal address)
                  let balance=utxoSum utxos
                      utxoCount=case utxos of { UTxO map -> Map.size  map }
                  putStrLn $ "Wallet Address :  " ++ T.unpack (serialiseAddress address)
                  putStrLn $ "Utxo Count     :  " ++ show utxoCount
                  putStrLn $ toConsoleText "  " balance
                  putStrLn $ "Wallet \"" ++ val ++ "\" is now active"
              else do
                putStrLn "Missing walletName: \n   wallet switch [walletname]\n \n Use \"wallet ls\" command to list available"
          "ls"     -> do
              workpath<- getWorkPath []
              contents<- getDirectoryContents   workpath
              let filtered= filter (isSuffixOf ".skey") contents
                  trimmed =  sort $ map T.unpack $ mapMaybe (T.stripSuffix ".skey" . T.pack) filtered
              if null trimmed
                then do
                  putStrLn  "No existing wallets. \n  You  can create one with \"keygen [walletname]\" command"
                else do
                  putStr "Avaialbe Wallets:\n  -  "
                  putStrLn $ intercalate "\n  -  " trimmed
          _        -> putStrLn    "Available commands are: \n - wallet ls  \n - wallet switch  [walletname]"
    Keygen walletName -> do
      key <- generateSigningKey AsPaymentKey
      network<- chainInfoFromEnv <&> getNetworkId
      if null walletName
        then  do
            putStrLn $ "New Key : "  ++ T.unpack   (  serialiseToBech32 key)
            putStrLn $ "Address : "  ++ T.unpack (serialiseAddress $  skeyToAddrInEra  key network)
        else do
          file <- getWorkPath [walletName ++ ".skey"]
          exists <- doesFileExist file
          if exists
            then
              putStrLn $   file ++ " : File Already exists"
            else do
              writeFile file (T.unpack   (  serialiseToBech32 key))
              putStrLn $ "Sign Key saved to : "++ file
              putStrLn $ "Address : "  ++ T.unpack (serialiseAddress $  skeyToAddrInEra  key network)
    
    UtxoSplit assetText countStr  -> do
      context <- chainInfoFromEnv >>= withDetails
      let network =getNetworkId  context
      asset <- parseAssetIdText $ T.pack assetText
      skey<- getCurrentSkey
      let count =read countStr  ::Integer
          ownAddr= skeyToAddrInEra skey network
      utxos <- queryUtxosOf context (AddressModal  ownAddr)
      let totalAssets = utxoSum utxos
          Quantity assetAmount = selectAsset totalAssets asset
          amountPerUtxo = assetAmount `div` count
          operation = mconcat ( replicate (fromInteger count -1 ) $ txPayTo ownAddr (valueFromList [(asset, Quantity amountPerUtxo)]))
                     <>  txPayTo ownAddr (valueFromList [(asset, Quantity $ assetAmount -  amountPerUtxo *(count -1 ))])
      txBodyE  <- txBuilderToTxBodyIO context operation
      case txBodyE of
        Left err -> error $ "Error : " ++ show err
        Right txBody -> do
          tx <- signAndSubmitTxBody (getConnectInfo context) txBody [skey]
          putStrLn $ "Submited Tx :"++ tail (init $ show (getTxId txBody))

      -- payToAddress :: IsNetworkCtx v => v  -> PaymentReqModel -> IO TxResponse
      -- payToAddress ctx (PaymentReqModel sKey valueList (AddressModal receiver) _ _)=do
      --   let txOperation= txPayTo receiver valueSent
      --   putStrLn $ "Paying " ++ show valueSent
  -- submitAndRespond ctx txOperation [] (skeyToAddrInEra sKey $ networkCtxNetwork ctx) [sKey]
        -- where
        --   valueSent= valueFromList $ map (\(CostModal c) -> c) valueList
        --     putStrLn "welcome master"

getCurrentSkey:: IO (SigningKey  PaymentKey)
getCurrentSkey = getCurrentWallet <&> snd

getCurrentWallet :: IO (String, SigningKey PaymentKey)
getCurrentWallet = do
  file <- getWorkPath ["skey.default"]
  fileExists <-  doesFileExist file
  if fileExists
    then do
      walletName <- readFile file
      skeyFile<-  getWorkPath [ T.unpack (strip (T.pack walletName)) ++ ".skey"]
      skey<- readSignKey skeyFile
      pure (walletName,skey)
    else
      fail $ "file doesn't exist :" ++ file