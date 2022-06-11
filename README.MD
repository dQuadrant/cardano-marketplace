Cardano Simple Marketplace
==========================

Webapp and cli for marketplace in cardano testnet.

#### marketplace-cli
This  component is command line tool for interacting with the marketplace. Cli used kuber library, which handles transaction creation and submission to node 

![something](./docs/cli.svg)


#### marketplace-frontend
Frontend vue project is located [here](./frontend).
-  It connects to an existing kuber server to construct transactions.
- Lists tokens onSale using blockfrost APIs.

![something](./docs/frontend.svg)





### Project structure

- **marketplace-plutus/** - contains plutus contract code for simple marketplace
- **marketplace-cli/** - contains entry point for cli and cli commands and their parsing 
- **marketplace-core/** - contains marketplace core functions and  interaction with kuber library
- **frontend/** - contains client side for marketplace


### Setting Up Locally

To prepare your system for building kuber from sources, follow these instructions:

    The steps can be summarized as 
    - install system dependencies for ghc and cardano-node
    - install ghc compiler and tools with ghcup
    - install iokhk patch of libsodium on the system
 
 The steps are described in detailed in the documentation of [building-cardano-node-from-soruces](https://developers.cardano.org/docs/get-started/installing-cardano-node/)

<h3><b>Install ghcup</b></h3>

Check [this page](https://www.haskell.org/ghcup/install/) for further explanation on the installation process.

#### Setup ghc and cabal 

```bash
ghcup install ghc 8.10.7
ghcup install cabal 3.6.2.0 
ghcup install hls # for language support in vs-code
ghcup set ghc 8.10.7
ghcup set cabal 3.6.2.0
```

#### Configuring the build options

We explicitly use the GHC version that we installed earlier.  This avoids defaulting to a system version of GHC that might be older than the one you have installed.

```bash
cabal configure --with-compiler=ghc-8.10.7
```


## Usage:
- [Using frontend](./frontend) : (Preferred Way) Its easier to get started.
- [Using Cli](./docs/cli.md)
