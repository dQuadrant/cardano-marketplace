{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Redundant bracket" #-}
{-# LANGUAGE DeriveAnyClass #-}

module Cardano.Marketplace.Server
where

import Control.Exception
  ( Exception,
    IOException,
    catch,
    throw, SomeException (SomeException), try, throwIO
  )
import Control.Monad.IO.Class (MonadIO (liftIO))
import Data.Aeson (FromJSON, ToJSON (toJSON), decode, KeyValue ((.=)), object)
import Data.Typeable (Proxy (..))
import GHC.Generics (Generic)
import Servant
import Cardano.Api (ChainTip, UTxO (UTxO), TxIn (TxIn), TxOut (TxOut), SerialiseAddress (serialiseAddress))
import Cardano.Marketplace.V1.RequestModels
import Cardano.Marketplace.V1.Core
import GHC.Conc.IO (threadDelay)
import           Network.Wai.Middleware.Servant.Errors (errorMw, HasErrorBody(..))
import Network.Wai.Handler.Warp (run)
import Network.HTTP.Types
import Cardano.Kuber.Api
import Cardano.Marketplace.V1.ServerRuntimeContext (resolveContext, RuntimeContext (runtimeContextMarket, runtimeContextCardanoConn))
import Data.List (intercalate)
import Control.Monad.State (evalState, evalStateT, runState, State, StateT (runStateT))
import qualified Data.Map as Map
import Cardano.Api.Shelley (AlonzoEra)
import GHC.Conc (atomically, newTVar, newTVarIO)
import Plutus.Contracts.V1.Marketplace
import Control.Monad.Reader (ReaderT(runReaderT))
import qualified Data.Text as T
import qualified Data.ByteString as ByteString
import qualified Data.ByteString.Lazy.Char8 as LBS
import Data.String (IsString(fromString))

import Servant.Exception         (Exception (..), Throws, ToServantErr (..), mapException)
import Servant.Exception.Server
import Data.Data (typeOf)
import GHC.IO.Exception (IOErrorType(UserError))

type HttpAPI = Throws FrameworkError  :>  (
              -- legacy endpoints

              -- directsale endpoints
                    ( "api" :> "v1" :> "sale"                :> ReqBody '[JSON] SellReqBundle :> Post '[JSON] SaleCreateResponse )
              -- :<|>  ( "api" :> "v1" :> "sale"  :>  "buy"     :> ReqBody '[JSON] BuyReqModel  :> Post '[JSON] TxResponse)
              -- :<|>  ( "api" :> "v1" :> "sale"  :>  "cancel"  :> ReqBody '[JSON] WithdrawReqModel  :> Post '[JSON] TxResponse)
              --  Auction endpoints
              -- :<|>  ("api" :> "v1" :> "auction"               :> ReqBody '[JSON] StartAuctionBundle   :> Post '[JSON] AuctionCreateResponse)
              -- :<|>  ("api" :> "v1" :> "auction" :> "bid"      :> ReqBody '[JSON] BidReqModel  :> Post '[JSON] TxResponse)
              -- :<|>  ("api" :> "v1" :> "auction" :> "finalize" :> ReqBody '[JSON] FinalizeAuctionModel  :> Post '[JSON] TxResponse)
              -- :<|>  ("api" :> "v1" :>"auction" :> "cancel"   :> ReqBody '[JSON] CancelAuctionModel :> Post '[JSON] TxResponse )

               -- General endpoints
              :<|>  "api" :> "v1" :> "addresses"           :> Capture "address" String  :> "balance" :> Get '[JSON] BalanceResponse
              :<|>  "api" :> "v1" :> "tx" :> "submit"      :> ReqBody '[JSON] SubmitTxModal  :> Post '[JSON] TxResponse

              -- operator endpoints
              -- :<|>  "operator" :> "v1" :> "sale"    :> "cancel"  :> ReqBody '[JSON] OperatorWithdrawModel :> Post '[JSON] TxResponse
              -- :<|>  "operator" :> "v1" :> "auction" :> "cancel"  :> ReqBody '[JSON] OperatorCancelAuctionModel  :> Post '[JSON] TxResponse
              -- :<|>  "operator" :> "v1" :> "auction" :> "finalize"  :> ReqBody '[JSON] FinalizeAuctionModel  :> Post '[JSON] TxResponse

    )

-- server :: (MonadIO m) =>
--   RuntimeContext
--   -> (SellReqBundle -> m SaleCreateResponse)
--     :<|> ((BuyReqModel -> m TxResponse)
--     :<|> ((WithdrawReqModel -> m TxResponse)
--     :<|> ((StartAuctionBundle  -> m AuctionCreateResponse)
--     :<|> ((BidReqModel -> m TxResponse)
--     :<|> ((FinalizeAuctionModel -> m TxResponse)
--     :<|> ((CancelAuctionModel -> m TxResponse)
--     :<|> ((String -> m BalanceResponse)
--     :<|> ((SubmitTxModal -> m TxResponse)
--     :<|> ((OperatorWithdrawModel -> m TxResponse)
--     :<|> ((OperatorCancelAuctionModel -> m TxResponse)
--     :<|> (FinalizeAuctionModel -> m TxResponse)))))))))))
server runtimeContext =
          errorGuard (placeOnMarket  networkContext market)
    -- :<|>  errorGuard (buyToken networkContext market)
    -- :<|>  errorGuard (withdrawCommand runtimeContext)
    -- :<|>  errorGuard (placeOnAuction runtimeContext )
    -- :<|>  errorGuard (bidOnAuction runtimeContext )
    -- :<|>  errorGuard (finalizeAuction  False runtimeContext)
    -- :<|>  errorGuard (cancelAuctionCommand  runtimeContext)
    :<|>  errorGuard (getBalance networkContext )
    :<|>  errorGuard (submitTx networkContext)
    -- :<|>  errorGuard (operatorWithdraw runtimeContext)
    -- :<|>  errorGuard (operatorCancelAuction  runtimeContext)
    -- :<|>  errorGuard (finalizeAuction True runtimeContext )

    where
    networkContext= runtimeContextCardanoConn runtimeContext
    market=runtimeContextMarket runtimeContext

    errorHandler f= do
      result <- try  f
      case result of
        Left s@(SomeException e) ->  do
          case fromException s of
            Nothing -> do
              print e
              throwIO myerr
                where
                  myerr :: FrameworkError
                  myerr =  FrameworkError  LibraryError (show e)
            Just s@(FrameworkError _ msg) ->  do
              putStrLn msg
              throwIO s
            Just s@(FrameworkErrors errs) ->  do
              print errs
              throwIO s
        Right v -> pure v
    errorGuard f v = liftIO $ do
        errorHandler $ f v



proxyAPI :: Proxy HttpAPI
proxyAPI = Proxy

app :: RuntimeContext -> Application
app rCtx = serve proxyAPI (server rCtx)

startMarketServer :: IO ()
startMarketServer=do
      context <- resolveContext
      case context of
        Left ss -> putStrLn $ "RuntimeConfigurationError:\n - " ++ intercalate "\n - "  ss
        Right rc -> do
          let port=8081
          putStrLn $ "Market       : " ++ show (runtimeContextMarket rc)
          putStrLn $ "MarketAddress: " ++   T.unpack (serialiseAddress $  marketAddressShelley  (runtimeContextMarket rc) $ getNetworkId (runtimeContextCardanoConn   rc))
          putStrLn $ "Starting server on port " ++ show port ++"..."
        -- Structures error response as JSON objects
        -- with 'error' and 'status' strings as error object field keys
        -- note they can be changed to any other preferred strings.
          run port $ app rc
      pure ()

instance ToServantErr FrameworkError where
  status (FrameworkError _ _ )= status400
  status (FrameworkErrors _ )= status400

instance MimeRender PlainText FrameworkError where
  mimeRender ct = mimeRender ct . show
