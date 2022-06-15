export NETWORK="9"
export TESTNET_MAGIC="9"
export CARDANO_CLI="${CARDANO_CLI:-cardano-cli-33}"
export BASE="${BASE:-$HOME/projects/cardano-marketplace}"

export WORK="${WORK:-$HOME/work}"
export UTXO_VKEY="${UTXO_VKEY:-$HOME/projects/cardano-marketplace/pay.vkey}"
export UTXO_SKEY="${UTXO_SKEY:-$HOME/projects/cardano-marketplace/pay.skey}"
export UTXO_ADDR="${UTXO_ADDR:-$HOME/projects/cardano-marketplace/pay.addr}"

utxoaddr=$(cat $UTXO_ADDR)

txin=

cd "$BASE"
# cabal run market-cli -- sell "$txin" 2000000 --signing-key-file pay.skey