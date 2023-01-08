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

forkano-wallet serve --port 8090 \
  --node-socket ${FORKANO_NODE_SOCKET_PATH} \
  --mainnet \
  --database ${ROOT}/wallet-db \
  --token-metadata-server https://tokens.forkano.net