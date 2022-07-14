

### Setting Up Locally

To prepare your system for building kuber from sources, follow these instructions:

    The steps can be summarized as 
    - install system dependencies for ghc and cardano-node
    - install ghc compiler and tools with ghcup
    - install iokhk patch of libsodium on the system
 
 The steps are described in detailed in the documentation of [building-cardano-node-from-soruces](https://developers.cardano.org/docs/get-started/installing-cardano-node/)

<h3><b>Install ghcup</b></h3>

**Important :** Check if ghc is installed using os package manager and uninstall it. (in case of ubuntu: `sudo apt remove ghc`)

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

#### Running the project
```
  cabal build
  cabal run market-cli help
```
For detaied options [Cli-docs](./cli.md)