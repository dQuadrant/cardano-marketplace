{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE FlexibleInstances #-}
module Cardano.Marketplace.Common.ConsoleWritable
where

import Cardano.Api
import qualified Data.Map as Map
import Cardano.Api.Shelley (Lovelace(Lovelace), TxBody (ShelleyTxBody))
import GHC.Real
import Data.List
import qualified Data.Set as Set
import Control.Monad (join)
import qualified Cardano.Ledger.Alonzo.Tx as LedgerBody
-- import Cardano.Ledger.Alonzo.TxBody (ppTxBody)
-- import Cardano.Ledger.Alonzo.Scripts (ppScript)
-- import qualified Shelley.Spec.Ledger.TxBody as LedgerBody (TxIn (TxIn))
class ConsoleWritable v where
  -- ^ toConsoleText prefix -> object -> Printable text
  toConsoleText ::   String-> v -> String

  toConsoleTextNoPrefix :: v -> String
  toConsoleTextNoPrefix v = toConsoleText "" v


instance IsCardanoEra era =>  ConsoleWritable (UTxO era) where
  toConsoleText prefix (UTxO utxoMap) =  prefix ++ intercalate (prefix ++ "\n") (map toStrings $ Map.toList utxoMap)
    where
      toStrings (TxIn txId (TxIx index),TxOut addr value hash _)=    showStr txId ++ "#" ++  show index ++"\t:\t" ++ (case value of
       TxOutAdaOnly oasie (Lovelace v) -> show v
       TxOutValue masie va ->  intercalate " +" (map vToString $valueToList va ) )
      vToString (AssetId policy asset,Quantity v)=show v ++ " " ++ showStr  policy ++ "." ++ showStr  asset
      vToString (AdaAssetId, Quantity v) = if v >99999
        then(
          let _rem= v `rem` 1_000_000
              _quot= v `quot` 1_000_000
          in
          case _rem of
                0 -> show _quot ++ " Ada"
                v-> show _quot ++"." ++ show _rem++ " Ada"
        )
        else show v ++ " Lovelace"

instance ConsoleWritable Value where
  toConsoleText prefix value= prefix ++ renderBalance value
    where
      renderBalance  balance =intercalate ("\n"++prefix) $  map renderAsset (valueToList balance)
      renderAsset (ass,q)=case ass of
        AdaAssetId  -> renderAda q
        AssetId p n        -> show q ++ "\t"++  showStr p  ++ "." ++ showStr n
      toTxOut (UTxO a) = Map.elems  a
      renderAda (Quantity q)= show ((fromIntegral q::Double)/1e6) ++ " Ada"

      toValue (TxOut _ v _ _) = case v of
        TxOutAdaOnly oasie lo -> lovelaceToValue lo
        TxOutValue masie va -> va
-- instance ConsoleWritable  (TxBody AlonzoEra ) where
--   toConsoleText prefix body= case body of
--     ShelleyTxBody era  ledgerBody scripts scriptData maybeAuxData scriptValidity
--       -> 
--         let (LedgerBody.TxBody (_ins) _collaterals _Outputs _deleCert _Withdrawals fee validity _updates witnessset _value _maybeintegrityHash _maybeAuxDataHash _maybeNetwork) = ledgerBody
--         in 
--         show (ppTxBody ledgerBody)
--         ++ newLine ++ "\nInputs   : " ++ intercalate (newLine ++ "\n           ") (map  txInStr $ Set.toList  _ins)
--         ++ newLine ++ "Scripts    : " ++ intercalate (newLine ++ "  ")  (map  (show . ppScript) scripts)
--         ++ newLine ++ "ScriptData : " ++  show  scriptData
--         ++ newLine ++ "\nAuxData  : " ++ show maybeAuxData

--     where
--       txInStr (LedgerBody.TxIn v v2) = show v ++ "#" ++ show v2
--       -- ppTxIn (LedgerBody.TxIn)= 
--       newLine= "\n" ++ prefix
--       showInput x = show x

showStr :: Show a => a -> [Char]
showStr x = init $ tail $ show x