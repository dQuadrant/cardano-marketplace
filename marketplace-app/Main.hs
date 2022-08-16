{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE NumericUnderscores #-}
module Main


where

import Cardano.Kuber.Api
import GHC.Exception (SomeException)
import Control.Exception (try, throwIO)
import System.Environment (getEnv)
import Cardano.Api
import Cardano.Marketplace.V1.Core (marketScriptAddr)
import Cardano.Marketplace.V1.ServerRuntimeContext
import Cardano.Kuber.Util (readSignKey, skeyToAddrInEra)
import Plutus.Contracts.V2.Marketplace (marketScript)

getTestChainInfo :: IO DetailedChainInfo
getTestChainInfo = do
  sockEnv <- try $ getEnv "CARDANO_NODE_SOCKET_PATH"
  socketPath <- case sockEnv of
    Left (e::SomeException) -> error "Socket File is Missing: Set environment variable CARDANO_NODE_SOCKET_PATH"
    Right s -> pure s
  let networkId = Testnet (NetworkMagic 2)
      connectInfo = ChainConnectInfo $ localNodeConnInfo networkId socketPath
  withDetails connectInfo

submitTransaction :: ChainInfo v => v -> TxBuilder -> SigningKey PaymentKey -> IO (Tx BabbageEra)
submitTransaction dcInfo txOperations sKey = do
  txBodyE <- txBuilderToTxBodyIO dcInfo txOperations
  txBody <- case txBodyE of
    Left fe -> throwIO fe
    Right txBody -> pure txBody
  let tx = signTxBody txBody [sKey]
  result <- submitTx (getConnectInfo dcInfo) tx
  case result of
    Left err -> throwIO err
    Right _ -> do
      putStrLn $ "Transaction submitted sucessfully"
      pure tx

main = do
    dcInfo <- getTestChainInfo
    let nwId = getNetworkId dcInfo
    scriptHolderSKey <- readSignKey "pay2.skey"
    let scriptHolderAddr = skeyToAddrInEra scriptHolderSKey nwId
    ctx <- resolveContext dcInfo
    case ctx of
      Left ss -> fail "error on resloving context."
      Right (RuntimeContext _ market _ _ _ _) -> do
        let txOps = txPayToWithReference (marketScript market) scriptHolderAddr (lovelaceToValue $ Lovelace 25_000_000)
                <> txWalletAddress scriptHolderAddr
        -- submitTransaction dcInfo txOps scriptHolderSKey
        print "Done"
