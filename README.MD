Cardano Simple Marketplace
==========================

Cardano Market Place contains a simple  market place contract loacted
on marketplace-plutus.

The folder structure is 
- **/frontend** - contains client side for marketplace
- **/marketplace-cli** - contains entry point for cli and cli commands and their parsing 
- **/marketplace-core** - contains marketplace core operations such as listing market 
utxos, buy sell of token etc which uses kuber library for building and submitting transactions
- **/marketplace-plutus** - contains plutus contract code for simple marketplace

Kuber library used functions and their working
- **For selling token** 
  - **txPayToScript** - find market address from script, prepare value to be locked and obtain datum hash
  - **txWalletAddress** - The address to be used for selecting utxos when creating transaction i.e. seller address
- **For buying token**
  - **txPayTo** - For paying the seller pay the required value to the seller address obtained from datum
  - **txRedeemUtxo** - Use txIn and txOut from market utxos, script, datum and redeemer
  - **txWalletAddress** - The address to be used for selecting utxos when creating transaction i.e. buyer address

### Setting Up

To prepare your system for building kuber from sources, follow these instructions:

    The steps can be summarized as 
    - install system dependencies for ghc and cardano-node
    - install ghc compiler and tools with ghcup
    - install iokhk patch of libsodium on the system
 
 The steps are described in detailed in the documentation of [building-cardano-node-from-soruces](https://developers.cardano.org/docs/get-started/installing-cardano-node/)

<h3><b>Install ghcup</b></h3>

```
Check [this page](https://www.haskell.org/ghcup/install/) for further explanation on the installation process.
```
<h3><b>Setup ghc and cabal</b></h3>

```
ghcup install ghc 8.10.7
ghcup install cabal 3.6.2.0
ghcup set ghc 8.10.7
ghcup set cabal 3.6.2.0
```

<h3><strong>Configuring the build options</strong></h3>

We explicitly use the GHC version that we installed earlier.  This avoids defaulting to a system version of GHC that might be older than the one you have installed.

```bash
cabal configure --with-compiler=ghc-8.10.7
```

Usage:
 - [Using Cli](./docs/cli.md)
 