echo "CARDANO_NODE_SOCKET_PATH = $CARDANO_NODE_SOCKET_PATH"
echo "GENESIS_ADDRESS = $GENESIS_ADDRESS"
echo "GENESIS_SKEY_FILE = $GENESIS_SKEY_FILE"
echo "WALLET_ADDRESS = $WALLET_ADDRESS"

# fund from cluster
mkdir .cluster-address
cardano-cli query utxo \
    --address $GENESIS_ADDRESS \
    --testnet-magic 42 \
    --socket-path $CARDANO_NODE_SOCKET_PATH \
    --out-file .cluster-address/genesis-utxos.json

export GENESIS_TXIN=$(jq -r 'keys[0]' .cluster-address/genesis-utxos.json)
echo "GENESIS_TXIN = $GENESIS_TXIN"

cardano-cli conway transaction build \
    --tx-in $GENESIS_TXIN \
    --tx-out $WALLET_ADDRESS+300000000000000 \
    --out-file .cluster-address/fund-wallet-address.tx \
    --change-address $GENESIS_ADDRESS \
    --testnet-magic 42 \
    --socket-path $CARDANO_NODE_SOCKET_PATH

cardano-cli conway transaction sign \
    --tx-body-file .cluster-address/fund-wallet-address.tx \
    --signing-key-file $GENESIS_SKEY_FILE \
    --testnet-magic 42 \
    --out-file .cluster-address/fund-wallet-address.tx \

cardano-cli transaction submit \
    --tx-file .cluster-address/fund-wallet-address.tx \
    --testnet-magic 42 \
    --socket-path $CARDANO_NODE_SOCKET_PATH

echo "Funding Wallet..."
sleep 5

echo "WALLET BALANCE:"
cardano-cli query utxo --address $WALLET_ADDRESS --testnet-magic 42 --socket-path $CARDANO_NODE_SOCKET_PATH
