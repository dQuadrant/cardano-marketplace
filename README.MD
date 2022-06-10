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
