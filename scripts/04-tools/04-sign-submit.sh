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

tx="hKYAgYJYINt91BjlflxraNcJOniuJWqvXGJfM6jxAMRNyTA7zk/2AQGBogBYOQGyrX7tgOP3majVntcyssuMkKktCka6rnHw8ZLVa0svzoDYL0asZSITXG0MjAMO7AS+mSjEraNgZAEadyEP1gIaAAKs/QMbAAAAB5G5w4AEgoIAggBYHGtLL86A2C9GrGUiE1xtDIwDDuwEvpkoxK2jYGSDAoIAWBxrSy/OgNgvRqxlIhNcbQyMAw7sBL6ZKMSto2BkWBxSdOdOYiOafcX/4n+jU6eM14pdabnTzgH8Ky0UCACg9fY="
sx="hKYAgYJYINt91BjlflxraNcJOniuJWqvXGJfM6jxAMRNyTA7zk/2AQGBogBYOQGyrX7tgOP3majVntcyssuMkKktCka6rnHw8ZLVa0svzoDYL0asZSITXG0MjAMO7AS+mSjEraNgZAEadyEP1gIaAAKs/QMbAAAAB5G5w4AEgoIAggBYHGtLL86A2C9GrGUiE1xtDIwDDuwEvpkoxK2jYGSDAoIAWBxrSy/OgNgvRqxlIhNcbQyMAw7sBL6ZKMSto2BkWBxSdOdOYiOafcX/4n+jU6eM14pdabnTzgH8Ky0UCAChAIKCWCAxicYakBev+3IYqlyc7A3A/BQmc3gBJGPJSq85wJ7HBlhAftvpy8xXfzKr1+odwGBAzyLC6iP4XFa4X3QDvsg+6Dbd9m/3bPZR2rh8L4jl/uSs0VYtaAj8380r1yk45h93D4JYIKqNdJhYlgn51+ju1NhVijE23snTKEviNmjR7HZExeTAWECaotx+tZ+E0TibAgcTOtQ4fIyDr43Ytm5M8OHAuw4GSGaMcT5jyH6aWTbiPGemgLVqPpvWjKKvX38AnaF9XBEH9fY="


read -s -p "Write the wallet passphrase: " passphrase

wallet=186ce51d40675ce69abb2cba6af82b16e8f01419
#curl -X POST http://localhost:8090/v2/wallets/${wallet}/transactions-sign -d '{"passphrase":"'${passphrase}'", "transaction":"'${tx}'"}' -H "Content-Type: application/json"

#curl -X POST http://localhost:8090/v2/wallets/${wallet}/transactions-submit -d '{"transaction":"'${sx}'"}' -H "Content-Type: application/json"
