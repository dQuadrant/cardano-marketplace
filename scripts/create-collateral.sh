export NETWORK="9"
export BASE="${BASE:-$HOME/projects/cardano-marketplace}"

cd "$BASE"
cabal run market-cli -- createcollateral --signing-key-file pay.skey