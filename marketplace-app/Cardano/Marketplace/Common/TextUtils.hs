{-# LANGUAGE FlexibleContexts #-}
module Cardano.Marketplace.Common.TextUtils
where

import Data.ByteString (ByteString)
import Data.Text.Conversions (ToText (toText), FromText (fromText), Base16 (unBase16, Base16), convertText, UTF8 (UTF8), DecodeText (decodeText))
import Data.Functor ((<&>))
import Cardano.Contrib.Easy.Error
import Cardano.Api
import Cardano.Contrib.Easy.Util
import Data.Text.Lazy (Text)
import System.Console.CmdArgs.GetOpt (convert)
import qualified Data.Text as Data.Text.Internal

unHex ::  ToText a => a -> Maybe  ByteString
unHex v = convertText (toText v) <&> unBase16

unHexBs :: ByteString -> Maybe ByteString
unHexBs v =  decodeText (UTF8 v) >>= convertText  <&> unBase16

toHexString :: (FromText a1, ToText (Base16 a2)) => a2 -> a1
toHexString bs = fromText $  toText (Base16 bs )




-- data SimpleMonadFail = SimpleMonadFail String

-- instance IsString SimpleMonadFail

addrStrPkh string=do 
  v <-unMaybe (SomeError "Not a valid address string") $ deserialiseAddress AsShelleyAddress  (toText string ) 
  unMaybe (SomeError " addr cannot be converted to pkh")   $ addrToMaybePkh  v 


pkhToAddr  network pkh= do
  unMaybe (SomeError "pkh cannot be converted to addr") $ pkhToMaybeAddr network pkh

  
  