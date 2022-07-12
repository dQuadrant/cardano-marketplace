export NETWORK="9"
export BASE="${BASE:-$HOME/projects/cardano-marketplace}"

cd "$BASE"
cabal run market-cli -- balance --signing-key-file pay.skey