export SOCKET_PATH='/home/reeshav/cardano-node-tests/dev_workdir/state-cluster0/bft1.socket'
echo "SOCKET_PATH = $SOCKET_PATH"

export GENESIS_ADDRESS=$(cat /home/reeshav/cardano-node-tests/dev_workdir/state-cluster0/shelley/genesis-utxo.addr)
echo "GENESIS_ADDRESS = $GENESIS_ADDRESS"

export GENESIS_SKEY_FILE='/home/reeshav/cardano-node-tests/dev_workdir/state-cluster0/shelley/genesis-utxo.skey'
echo "GENESIS_SKEY_FILE = $GENESIS_SKEY_FILE"

export WALLET_ADDRESS=$(cat /home/reeshav/cardano-marketplace/payment.addr)
echo "WALLET_ADDRESS = $WALLET_ADDRESS"

# fund from cluster

cardano-cli query utxo \
    --address $GENESIS_ADDRESS \
    --testnet-magic 42 \
    --socket-path $SOCKET_PATH \
    --out-file .cluster-address/genesis-utxos.json

export GENESIS_TXIN=$(jq -r 'keys[0]' .cluster-address/genesis-utxos.json)
echo "GENESIS_TXIN = $GENESIS_TXIN"

cardano-cli conway transaction build \
    --tx-in $GENESIS_TXIN \
    --tx-out $WALLET_ADDRESS+300000000000000 \
    --out-file .cluster-address/fund-wallet-address.tx \
    --change-address $GENESIS_ADDRESS \
    --testnet-magic 42 \
    --socket-path $SOCKET_PATH

cardano-cli conway transaction sign \
    --tx-body-file .cluster-address/fund-wallet-address.tx \
    --signing-key-file $GENESIS_SKEY_FILE \
    --testnet-magic 42 \
    --out-file .cluster-address/fund-wallet-address.tx \

cardano-cli conway transaction submit \
    --tx-file .cluster-address/fund-wallet-address.tx \
    --testnet-magic 42

echo "Funding Wallet..."
sleep 5

echo "WALLET BALANCE:"
cardano-cli conway query utxo --address $WALLET_ADDRESS --testnet-magic 42 
