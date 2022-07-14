Running the cli
=================

1. Clone this repositroy. And build the project.

    ```bash
    git clone git@github.com:dquadrant/cardano-marketplace.git
    cd cardano-marketplace
    cabal update
    cabal build
    ```
2. Now you can run the cli commands

**Note** before using market-cli, You should be failiar with  `cardano-cli`  and be able to at last  following : 
- generate signing key
- obtain enterprise address corresponding to the signkey
- querying account balance 

market-cli required two environment variables to be properly configured for it to be able to work
- `CARDANO_NODE_SOCKET_PATH` : Cardano node's socket file path. (&nbsp;Default&nbsp;:&nbsp;$HOME/.cardano/testnet/node.socket&nbsp;)
- `NETWORK : ` `testnet` or `mainnet` or networkMagic  number (&nbsp;Defaault&nbsp;:&nbsp;testnet&nbsp;)

### List Market Utxos

```
$ CARDANO_NODE_SOCKET_PATH=./node.socket  cabal run market-cli ls
```


### Place Token on Sell
<hr>
For placing token on sell - sell command first argument is assetId and second argument is price of the token to be placed

```
cabal run market-cli sell '<PolicyId.AssetName>' <Cost in Interger>
```
Example 
```bash
$ cabal run market-cli sell 'fe0f87df483710134f34045b516763bad1249307dfc543bc56a9e738.testtoken' 2000000

Transaction submitted sucessfully with transaction hash  `eba7d070d45a90402b8f289ba5324bc425fe87c25d98c7bfaccac2802e1da7fa`
Datum to be used for buying :
{"fields":[{"fields":[{"fields":[{"bytes":"edea1516f727e4dd650833f37b80109d55b64529244595612aacf62c"}],"constructor":0},{"fields":[],"constructor":1}],"constructor":0},{"int":2000000}],"constructor":0}

```


### Buy From Marketplace
For buying token from the market, first find out the utxo that contains the asset you want to buy using

```
cabal run market-cli ls
```

Example output:

```
Market Address : addr_test1wqsewsqrurhxer8wx598p7naf9mmcwhr2jchkq6srtf78hctj0p2r
Market UTXOs:
  5e1f2e5a8844040a892b30135c667fa9ea74df41dc278bd9195c4efdf6ea19c3#0       [Cost 10.0Ada] f75cdb5143473e94ef9d11221909c0d69187e4ac97039474fa526091.token1
  65bc523e93c22ffe8f104707505f48633a26f8efcd1f5c99febfbadf67a829f3#0     [Cost 20.0Ada] f75cdb5143473e94ef9d11221909c0d69187e4ac97039474fa526091.token2
```

Note the string containig #0 in format txId#txIndex copy that as txIn


```bash
cabal run market-cli buy '<txIn>' 
```

Example

```
cabal run market-cli buy 'eba7d070d45a90402b8f289ba5324bc425fe87c25d98c7bfaccac2802e1da7fa#0' '{"fields":[{"fields":[{"fields":[{"bytes":"edea1516f727e4dd650833f37b80109d55b64529244595612aacf62c"}],"constructor":0},{"fields":[],"constructor":1}],"constructor":0},{"int":2000000}],"constructor":0}'
Transaction submitted sucessfully with transaction hash 172cbdd784d3eaa70d000688cd290356ebf52136ccd7dbc55b33788ca10e7f05
```

### Withdraw Token
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

```bash
$ cabal run market-cli withdraw 'eba7d070d45a90402b8f289ba5324bc425fe87c25d98c7bfaccac2802e1da7fa#0' '{"fields":[{"fields":[{"fields":[{"bytes":"edea1516f727e4dd650833f37b80109d55b64529244595612aacf62c"}],"constructor":0},{"fields":[],"constructor":1}],"constructor":0},{"int":2000000}],"constructor":0}'
Transaction submitted sucessfully with transaction hash 172cbdd784d3eaa70d000688cd290356ebf52136ccd7dbc55b33788ca10e7f05
```