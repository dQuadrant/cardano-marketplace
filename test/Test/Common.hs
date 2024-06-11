{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Test.Common where
import Cardano.Kuber.Api
import Cardano.Api
import Cardano.Api.Shelley
import qualified Cardano.Ledger.Shelley.Core as L
import Control.Lens ((^.))
import qualified Cardano.Ledger.Alonzo.TxWits as L
import qualified Cardano.Ledger.Alonzo.Scripts as L
import qualified Cardano.Api.Ledger as L
import Cardano.Marketplace.Common.TransactionUtils
import qualified Data.ByteString.Char8 as BS8
import Test.Hspec (shouldSatisfy)
import qualified Data.Map as Map
import qualified Control.Concurrent as Control
import qualified Data.Set as Set

increment :: Int -> Int
increment x = x + 1

runTransactionTest :: (HasKuberAPI a, HasSubmitApi a, HasChainQueryAPI a) =>
  a
  -> String
  -> TxBuilder
  -> Kontract a w FrameworkError TxBuilder
  -> IO (Either FrameworkError (Tx ConwayEra))
runTransactionTest chainInfo  action walletBuilder builderKontract = do 
    result <-evaluateKontract chainInfo  $ 
          performTransactionAndReport 
          action 
          walletBuilder  
          (builderKontract)
    result `shouldSatisfy` (\case
        Left _ -> False
        Right _ -> True
      ) 
    pure result

performTransactionAndReport :: (HasKuberAPI api,HasSubmitApi api,HasChainQueryAPI api) => 
  String -> 
  TxBuilder -> 
  Kontract api w FrameworkError TxBuilder -> 
  Kontract api w FrameworkError (Tx ConwayEra) 
performTransactionAndReport action wallet builderKontract = do 
  builder <- builderKontract 
  tx <- runBuildAndSubmit  $ builder <> wallet 
  let txEnvelope =  serialiseTxLedgerCddl ShelleyBasedEraConway tx 
  liftIO$ putStrLn $ action ++ " Tx submitted : " ++ (BS8.unpack $  prettyPrintJSON txEnvelope) 
  liftIO $ reportExUnitsandFee tx 
  waitTxConfirmation tx 180 
  liftIO $ do putStrLn $ action ++ " Tx Confirmed: " ++ (show $ getTxId (getTxBody tx)) 
  pure (tx)

reportExUnitsandFee:: Tx ConwayEra -> IO() 
reportExUnitsandFee  = (\case  
      ShelleyTx era ledgerTx -> let 
        txWitnesses = ledgerTx ^. L.witsTxL 
        -- this should be exUnits of single script involved in the transaction
        exUnits = map snd $ map snd $  Map.toList $ L.unRedeemers $  txWitnesses ^. L.rdmrsTxWitsL
        in do 
          case exUnits of 
            [eunit]-> let eu = L.unWrapExUnits eunit
                          (mem,cpu) =   (L.exUnitsMem' eu,L.exUnitsSteps' eu)
                      in putStrLn $  "  ExUnits:  memory = " ++ show mem ++ " cpu = " ++ show cpu
            _       -> pure () 
          putStrLn $  "  Fee :   " ++ show (L.unCoin $ ledgerTx ^. L.bodyTxL ^. L.feeTxBodyL ) 
    )


waitTxConfirmation :: HasChainQueryAPI a => Tx ConwayEra -> Integer
      -> Kontract a w FrameworkError ()
waitTxConfirmation tx totalWaitSecs =  
    let txId = getTxId$ getTxBody tx
    in waitTxId txId  totalWaitSecs
  where
    waitTxId txId remainingSecs = 
      if remainingSecs < 0 
        then kError TxSubmissionError $ "Transaction not confirmed after  " ++ show totalWaitSecs ++ " secs"
        else do 
          (UTxO uMap):: UTxO ConwayEra <- kQueryUtxoByTxin $  Set.singleton (TxIn txId (TxIx 0))
          liftIO $ Control.threadDelay 2_000_000
          case Map.toList uMap of 
            [] -> waitTxId txId (remainingSecs - 2)
            _ -> pure ()