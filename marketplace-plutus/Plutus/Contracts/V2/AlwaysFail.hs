{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE ImportQualifiedPost #-}

module Plutus.Contracts.V2.AlwaysFail
  ( alwaysFailsScript
  , alwaysFailsScriptShortBs
  ,alwaysFailPlutusScript
  ) where

import Prelude hiding (($))

import Cardano.Api.Shelley (PlutusScript (..), PlutusScriptV2)
import Codec.Serialise ( serialise )
import Data.ByteString.Lazy qualified as LBS
import Data.ByteString.Short qualified as SBS

import Plutus.V2.Ledger.Api
    ( BuiltinData,
      Script,
      Validator,
      mkValidatorScript,
      unValidatorScript )
import PlutusTx qualified
import PlutusTx.Prelude ( BuiltinData, ($), error )

{-# INLINABLE mkValidator #-}
mkValidator :: BuiltinData -> BuiltinData -> BuiltinData -> ()
mkValidator _ _ _ = PlutusTx.Prelude.error ()

validator :: Validator
validator = mkValidatorScript $$(PlutusTx.compile [|| mkValidator ||])

alwaysFailPlutusScript :: Script
alwaysFailPlutusScript = unValidatorScript validator

alwaysFailsScriptShortBs :: SBS.ShortByteString
alwaysFailsScriptShortBs = SBS.toShort . LBS.toStrict $ serialise alwaysFailPlutusScript

alwaysFailsScript :: PlutusScript PlutusScriptV2
alwaysFailsScript = PlutusScriptSerialised alwaysFailsScriptShortBs