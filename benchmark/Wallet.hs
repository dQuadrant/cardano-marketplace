{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Wallet where
import Cardano.Api (SigningKey (..), AsType (..), serialiseToRawBytesHex, SerialiseAddress (serialiseAddress), AddressInEra)
import qualified Cardano.Address.Style.Shelley as Shelley 
import Cardano.Mnemonic (Mnemonic, mkSomeMnemonic, SomeMnemonic (..), MkMnemonicError(..))
import Data.ByteArray (convert, ScrubbedBytes)
import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as BS
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import GHC.TypeNats (Nat)
import Cardano.Address.Derivation (Depth(PaymentK, RootK))
import Cardano.Address.Derivation
import Cardano.Address.Style.Shelley (Role(..), deriveAccountPrivateKeyShelley, genMasterKeyFromMnemonicShelley, deriveAddressPrivateKeyShelley, liftXPub, delegationAddress)
import Cardano.Api.Shelley (PaymentKey, StakeCredential (StakeCredentialByKey))
import Cardano.Address.Style.Shelley (paymentAddress,Credential(..))
import Cardano.Address (unAddress, bech32)
import Cardano.Kuber.Util (toHexString)
import Cardano.Kuber.Data.Parsers (parseAddressBinary, parseSignKey, parseAddressRaw)
import Cardano.Api (ConwayEra, SerialiseAsRawBytes (deserialiseFromRawBytes))
import Control.Exception (throwIO)
import Cardano.Api (StakeKey, AddressInEra (AddressInEra), ShelleyBasedEra (ShelleyBasedEraConway), makeShelleyAddress, NetworkId (Testnet), NetworkMagic (NetworkMagic), PaymentCredential (PaymentCredentialByKey), Key (verificationKeyHash, getVerificationKey), StakeAddressReference (StakeAddressByValue), AddressTypeInEra (ShelleyAddressInEra))
import Cardano.Ledger.Address (serialiseAddr)
import GHC.Word (Word32)
-- Replace these with your seed words
seedWords :: [Text]
seedWords =
    ["safe","key","donate","table","foot","finish","original","firm","stairs",
    "gospel","illness","friend","pull","useful","process","sea","beef","mesh",
    "blast","shadow","wealth","rather","certain","lab"]

data ShelleyWallet = ShelleyWallet {
      wPaymentSkey :: SigningKey PaymentKey
    , wStakeSkey :: SigningKey StakeKey
    , wAddress :: AddressInEra ConwayEra
} deriving (Show)


genWallet :: Word32 -> IO ShelleyWallet
genWallet index =  do   
    let mnemonicResult = mkSomeMnemonic @'[ 24 ] seedWords
    descriminant <- case Shelley.mkNetworkDiscriminant 0 of 
        Left e -> error (show e)
        Right v -> pure v

    case mnemonicResult of
        Left err -> do
            putStrLn $ "Error creating mnemonic: " ++ show err
            error $ show  err
                
        Right mnemonic ->
            let
                rootXPrv = genMasterKeyFromMnemonicShelley @ScrubbedBytes mnemonic mempty 
                accountIndex ::  (Index 'Hardened 'AccountK) =(unsafeMkIndex $  (index + 0x80000000))
                stakeIndex :: (Index 'Soft 'DelegationK) = (unsafeMkIndex $  2)
                addressIndex :: (Index 'Soft 'PaymentK) = (unsafeMkIndex $  0)

                shelleyAccountRootKey = deriveAccountPrivateKeyShelley rootXPrv accountIndex 0x8000073c
                paymentKey = deriveAddressPrivateKeyShelley shelleyAccountRootKey UTxOExternal addressIndex
                addrPubKey = liftXPub $  toXPub paymentKey
                stakeKey = deriveAddressPrivateKeyShelley shelleyAccountRootKey Stake addressIndex
                -- xprvAccount  = deriveAccountPrivateKey rootXPrv (unsafeMkIndex @Soft 0 )

                -- addrXPub1 = toXPub <$> deriveAddressPrivateKey accXPrv UTxOExternal (unsafeMkIndex 0)
                -- addrXPub2 = deriveAddressPublicKey (toXPub <$> accXPrv) UTxOExternal (unsafeMkIndex 0)
                pSignkeyBytes = xprvPrivateKey paymentKey
                sSignkeyBytes = xprvPrivateKey stakeKey
                baseAddr =   delegationAddress 
                                descriminant  
                                (PaymentFromExtendedKey $ liftXPub $ toXPub paymentKey) 
                                (DelegationFromExtendedKey $ liftXPub $ toXPub stakeKey )
                in do
                    psKey<- errorOnLeft $ deserialiseFromRawBytes (AsSigningKey AsPaymentKey) $ BS.drop 32 pSignkeyBytes
                    ssKey <- errorOnLeft $ deserialiseFromRawBytes (AsSigningKey AsStakeKey) $ BS.drop 32 sSignkeyBytes
                    let paymentCred = PaymentCredentialByKey (verificationKeyHash $ getVerificationKey psKey)
                        stakeCred = StakeCredentialByKey (verificationKeyHash $ getVerificationKey ssKey)
                        walletAddress = makeShelleyAddress (Testnet $ NetworkMagic 1) paymentCred (StakeAddressByValue stakeCred)
                    pure $ ShelleyWallet psKey ssKey (AddressInEra (ShelleyAddressInEra ShelleyBasedEraConway) walletAddress  )


errorOnLeft (Left e) = error $ show e
errorOnLeft (Right v) = pure v