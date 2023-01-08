#!/usr/bin/env bash

set -e
# Unofficial bash strict mode.
# See: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -u
set -o pipefail

print_line() {
  printf '%*s\n\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' '-'
}

read_enter() {
  echo "Press enter to ${1}"
  read REPLY
}

UNAME=$(uname -s) SED=
case $UNAME in
  Darwin )      SED="gsed";;
  Linux )       SED="sed";;
esac

sprocket() {
  if [ "$UNAME" == "Windows_NT" ]; then
    # Named pipes names on Windows must have the structure: "\\.\pipe\PipeName"
    # See https://docs.microsoft.com/en-us/windows/win32/ipc/pipe-names
    echo -n '\\.\pipe\'
    echo "$1" | sed 's|/|\\|g'
  else
    echo "$1"
  fi
}

UNAME=$(uname -s) DATE=
case $UNAME in
  Darwin )      DATE="gdate";;
  Linux )       DATE="date";;
  MINGW64_NT* ) UNAME="Windows_NT"
                DATE="date";;
esac

ROOT=$(cat ~/forkano_root_dir)node-mainnet
export FORKANO_NODE_SOCKET_PATH=${ROOT}/main.sock

FORKANO_NET_URL="127.0.0.1"
#FORKANO_NET_URL="pools.forkano.net"

ID=4
PORT=300${ID}
NODE=node-spo${ID}
NODE_DIR=${ROOT}/${NODE}
ADDR_DIR=${NODE_DIR}/addresses
COLD_KEY_DIR=${NODE_DIR}/cold-keys
KEY_DIR=${NODE_DIR}/keys
PAYMENT_KEY="${KEY_DIR}/payment${ID}"
STAKE_KEY="${KEY_DIR}/stake${ID}"
COLD_KEY="${COLD_KEY_DIR}/cold$ID"
VRF_KEY="${KEY_DIR}/vrf$ID"


#forkano-wallet wallet list
forkano-wallet wallet list | jq -er '.[] | "Name: \(.name) - ID: \(.id)"'

echo "Paste the WALLET ID you wish to delegate and Press Enter"
read WALLET_ID

#forkano-wallet stake-pool list --stake 2000000000
forkano-wallet stake-pool list --stake 2000000000 | jq '.[] | "Pool ID: \(.id)"'

echo "Paste the POOL ID you want to use for delegation"
read POOL_ID

echo "Creating transaction for delegation..."
echo curl -X POST http://localhost:8090/v2/wallets/${WALLET_ID}/transactions-construct -d '{"delegations": [{"join":{"pool":"'${POOL_ID}'", "stake_key_index":"0H"}}]}' -H "Content-Type: application/json"
tx=$(curl -X POST http://localhost:8090/v2/wallets/${WALLET_ID}/transactions-construct -d '{"delegations": [{"join":{"pool":"'${POOL_ID}'", "stake_key_index":"0H"}}]}' -H "Content-Type: application/json" | jq -r '.transaction')
echo "The tx is"
echo ${tx}
echo ""
echo "This is not enough, now you MUST SIGN and SUBMIT the tx :("
echo "But... this script will help you! :)"
echo ""
read -s -p "Write the wallet passphrase: " passphrase

#echo "Now MANUALLY COPY AND PASTE the TX obtained before (that ugly string similar to hKYAgYJYINt91BjlflxraNcJOniuJWqvXGJfM6jxAMRNyTA7zk/2AQGBogBYOQGy"
#read tx

#SIGN
echo "Signing transaction..."
sx=$(curl -X POST http://localhost:8090/v2/wallets/${WALLET_ID}/transactions-sign -d '{"passphrase":"'${passphrase}'", "transaction":"'${tx}'"}' -H "Content-Type: application/json" | jq -r '.transaction')

#echo "Now MANUALLY COPY AND PASTE the Signed TX obtained before (that ugly string similar to hKYAgYJYINt91BjlflxraNcJOniuJWqvXGJfM6jxAMRNyTA7zk/2AQGBogBYOQGy but larger"
#echo "The signed tx is"
echo ${sx}
#read sx

echo "Submitting transaction"
echo "Are you ready? PRESS ENTER"
read REPLY
curl -X POST http://localhost:8090/v2/wallets/${WALLET_ID}/transactions-submit -d '{"transaction":"'${sx}'"}' -H "Content-Type: application/json"
echo ""