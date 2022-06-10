Running the cli
=================
1. Clone this repositroy. And build the project.

```bash
git clone git@github.com:dquadrant/cardano-marketplace.git
cd cardano-marketplace
cabal update
cabal build
```

3. Now you can run the cli commands
### List Market Utxos

- For listing available market utxos
```
cabal run market-cli ls
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
Market Address : addr_test1wzd8ssap4l5rge4aq59fh92gh7ey2zghxa6mzrpju38tw6g4p8ym9
  eba7d070d45a90402b8f289ba5324bc425fe87c25d98c7bfaccac2802e1da7fa#0	:	2 Ada +1 fe0f87df483710134f34045b516763bad1249307dfc543bc56a9e738.testtoken
```

Note the string containig #0 in format txId#txIndex copy that as txIn

Copy the datum printed from the sell output and execute the following command.

```bash
cabal run market-cli buy '<txIn>' '<datum>'
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