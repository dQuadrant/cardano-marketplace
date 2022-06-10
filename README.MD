<h1>Introduction</h1>
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
<hr>
<br>
<h1>Setting Up</h1>

To prepare your system for building kuber from sources, you can follow these instructions:

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


<h3><strong>Building and running</strong></h3>

1. Clone this repositroy. And Go to this reposiroty .

```bash
cd cardano-marketplace
```

2. Run the following commands
```
cabal update
cabal build
```
3. Now you can run the cli commands
<br><br>
## List Market Utxos
<hr>

- For listing available market utxos
```
cabal run market-cli ls
```


## Place Token on Sell
<hr>
For placing token on sell - sell command first argument is assetId and second argument is price of the token to be placed

```
cabal run market-cli sell '<PolicyId.AssetName>' <Cost in Interger>
```
Example Command
```bash
cabal run market-cli sell 'fe0f87df483710134f34045b516763bad1249307dfc543bc56a9e738.testtoken' 2000000
```
Example Output:
```json
Transaction submitted sucessfully with transaction hash eba7d070d45a90402b8f289ba5324bc425fe87c25d98c7bfaccac2802e1da7fa

Datum to be used for buying :
{"fields":[{"fields":[{"fields":[{"bytes":"edea1516f727e4dd650833f37b80109d55b64529244595612aacf62c"}],"constructor":0},{"fields":[],"constructor":1}],"constructor":0},{"int":2000000}],"constructor":0}

```


## Buy Token
<hr>
For buying token from the market - First find out the utxo that contains the asset you want to buy using

```
cabal run market-cli ls
```

Example output:

```
Market Address : addr_test1wzd8ssap4l5rge4aq59fh92gh7ey2zghxa6mzrpju38tw6g4p8ym9
  eba7d070d45a90402b8f289ba5324bc425fe87c25d98c7bfaccac2802e1da7fa#0	:	2 Ada +1 fe0f87df483710134f34045b516763bad1249307dfc543bc56a9e738.testtoken
```

Note the string containig #0 in format txId#txIndex copy that as txIn

Copy the datum printed from the sell output.


Now execute the following command.

```bash
cabal run market-cli buy '<txIn>' '<datum>'
```

For example command

```
cabal run market-cli buy 'eba7d070d45a90402b8f289ba5324bc425fe87c25d98c7bfaccac2802e1da7fa#0' '{"fields":[{"fields":[{"fields":[{"bytes":"edea1516f727e4dd650833f37b80109d55b64529244595612aacf62c"}],"constructor":0},{"fields":[],"constructor":1}],"constructor":0},{"int":2000000}],"constructor":0}'
```

Example output 

```
Transaction submitted sucessfully with transaction hash 172cbdd784d3eaa70d000688cd290356ebf52136ccd7dbc55b33788ca10e7f05
```

## Withdraw Token
<hr>
- For withdrawing token from the market - First find out the utxo that contains the asset you want to buy using. For withdraw to work it must be signed by the seller.

```
cabal run market-cli ls
```

Example output:

```
Market Address : addr_test1wzd8ssap4l5rge4aq59fh92gh7ey2zghxa6mzrpju38tw6g4p8ym9
  eba7d070d45a90402b8f289ba5324bc425fe87c25d98c7bfaccac2802e1da7fa#0	:	2 Ada +1 fe0f87df483710134f34045b516763bad1249307dfc543bc56a9e738.testtoken
```

Note the string containig #0 in format txId#txIndex copy that as txIn

Copy the datum printed from the sell output.


Now execute the following command.

```bash
cabal run market-cli withdraw '<txIn>' '<datum>'
```

For example command

```
cabal run market-cli withdraw 'eba7d070d45a90402b8f289ba5324bc425fe87c25d98c7bfaccac2802e1da7fa#0' '{"fields":[{"fields":[{"fields":[{"bytes":"edea1516f727e4dd650833f37b80109d55b64529244595612aacf62c"}],"constructor":0},{"fields":[],"constructor":1}],"constructor":0},{"int":2000000}],"constructor":0}'
```

Example output 

```
Transaction submitted sucessfully with transaction hash 172cbdd784d3eaa70d000688cd290356ebf52136ccd7dbc55b33788ca10e7f05
```