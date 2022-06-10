{-# LANGUAGE FlexibleContexts #-}
module Cardano.Marketplace.Common.TextUtils
where

import Data.ByteString (ByteString)
import Data.Text.Conversions (ToText (toText), FromText (fromText), Base16 (unBase16, Base16), convertText, UTF8 (UTF8), DecodeText (decodeText))
import Data.Functor ((<&>))

import Data.Text.Lazy (Text)
import qualified Data.Text as Data.Text.Internal

toHexString :: (FromText a1, ToText (Base16 a2)) => a2 -> a1
toHexString bs = fromText $  toText (Base16 bs)

  
  