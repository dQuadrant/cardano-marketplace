## Running Cardano-Marketplace Test and BenchMark on Private Testnet

### Step1: Setting up Testnet

- clone the IntersectMBO/cardano-node-tests repository
    ```sh
    git clone https://github.com/IntersectMBO/cardano-node-tests.git
    ```
- To run tests on the latest cardano-node 
    ```sh
    ~/cardano-node-tests$ nix flake update --accept-flake-config --override-input cardano-node "github:IntersectMBO/cardano-node/master"
    ```
    > you may change 'master' to the rev you want. For example, to run on cardano-node-8.9.4, use "github:IntersectMBO/cardano-node/8.9.4"
    ```sh 
    ~/cardano-node-tests$ nix develop --accept-flake-config .#venv
    ```
- to setup test environment
    ```sh
    ~/cardano-node-tests$ source ./prepare_test_env.sh conway # 'babbage' is also supported
    ```
- start testnet
  ```sh 
  ~/cardano-node-tests$ ./dev_workdir/conway_fast/start-cluster
  ```

### Step 2: Creating necessary Keys
You will need to create an address and necessaey keys in order to operate the marketplace. We can do that using cardano-cli. These keys can be created in the root folder i.e. the `cardano-marketplace` folder. 

```sh
cardano-cli address key-gen \
    --verification-key-file payment.vkey \
    --signing-key-file payment.skey

cardano-cli stake-address key-gen \
    --verification-key-file stake.vkey \
    --signing-key-file stake.skey

cardano-cli address build \
    --payment-verification-key-file payment.vkey \
    --stake-verification-key-file stake.vkey \
    --out-file payment.addr \
    --testnet-magic 42
```

### Step 3: Funding the address from private testnet
To run the marketplace on the private testnet, you'll need funds in your address, which must be sourced from the private testnet. You can use the genesis UTxO to transfer an adequate amount of funds to the address. However, be aware that these funds will be lost if the testnet is terminated or restarted.

export the following variables: 
- CARDANO_NODE_SOCKET_PATH
  - set the location of the socket created while starting the private testnet. This is in the dev_workdir folder of cardano-node-tests. 
  - Example:
    ```sh
    export CARDANO_NODE_SOCKET_PATH=/cardano-node-tests/dev_workdir/state-cluster0/bft1.socket`
    ```
- GENESIS_ADDRESS
  - set the private testnet's genesis UTxO's address in this variable
  - Example:
    ```sh
    export GENESIS_ADDRESS=$(cat /cardano-node-tests/dev_workdir/state-cluster0/shelley/genesis-utxo.addr)
    ```
- GENESIS_SKEY_FILE
  - set the private testnet's genesis address's payment signing key file location in this variable
  - Example:
    ```sh
    export GENESIS_SKEY_FILE='/cardano-node-tests/dev_workdir/state-cluster0/shelley/genesis-utxo.skey'
    ```
- WALLET_ADDRESS
  - set your own wallet address which was created in step 2. 
  - Example:
    ```sh
    export WALLET_ADDRESS=$(cat /cardano-marketplace/payment.addr)
    ```
- SIGNKEY_FILE
  - set your payment signing key file.
  - Example:
    ```sh
    export SIGNKEY_FILE='./cardano-marketplace/payment.skey'
    ```
After exporting these variables, run the address-setup script. 
```sh
./address-setup.sh
```
The address will be funded with 300000000000000 lovelace from the private testnet. 

## Step 4: Run Benchmark and Tests
To run the marketplace benchmark,
```sh
NETWORK=42 cabal bench
```
To run marketplace test,
```sh
NETWORK=42 cabal test market-test
```

